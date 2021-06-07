import 'dart:async';

import 'package:meta/meta.dart';
import 'package:collection/collection.dart';

import 'package:gql_exec/gql_exec.dart';
import 'package:gql_link/gql_link.dart' show Link;

import 'package:graphql/src/cache/cache.dart';
import 'package:graphql/src/core/observable_query.dart';
import 'package:graphql/src/core/_base_options.dart';
import 'package:graphql/src/core/mutation_options.dart';
import 'package:graphql/src/core/query_options.dart';
import 'package:graphql/src/core/query_result.dart';
import 'package:graphql/src/core/policies.dart';
import 'package:graphql/src/exceptions.dart';
import 'package:graphql/src/scheduler/scheduler.dart';

import 'package:graphql/src/core/_query_write_handling.dart';

bool Function(dynamic a, dynamic b) _deepEquals =
    const DeepCollectionEquality().equals;

class QueryManager {
  QueryManager({
    required this.link,
    required this.cache,
    this.alwaysRebroadcast = false,
  }) {
    scheduler = QueryScheduler(
      queryManager: this,
    );
  }

  final Link link;
  final GraphQLCache cache;

  /// Whether to skip deep equality checks in [maybeRebroadcastQueries]
  final bool alwaysRebroadcast;

  QueryScheduler? scheduler;
  static final _oneOffOpId = '0';
  int idCounter = 1;

  /// [ObservableQuery] registry
  Map<String, ObservableQuery> queries = <String, ObservableQuery>{};

  /// prevents rebroadcasting for some intensive bulk operation like [refetchSafeQueries]
  bool rebroadcastLocked = false;

  ObservableQuery watchQuery(WatchQueryOptions options) {
    final ObservableQuery observableQuery = ObservableQuery(
      queryManager: this,
      options: options,
    );

    setQuery(observableQuery);

    return observableQuery;
  }

  Stream<QueryResult> subscribe(SubscriptionOptions options) async* {
    assert(
      options.fetchPolicy != FetchPolicy.cacheOnly,
      "Cannot subscribe with FetchPolicy.cacheOnly: $options",
    );
    final request = options.asRequest;

    // Add optimistic or cache-based result to the stream if any
    if (options.optimisticResult != null) {
      // TODO optimisticResults for streams just skip the cache for now
      yield QueryResult.optimistic(
          data: options.optimisticResult as Map<String, dynamic>?);
    } else if (shouldRespondEagerlyFromCache(options.fetchPolicy)) {
      final cacheResult = cache.readQuery(
        request,
        optimistic: options.policies.mergeOptimisticData,
      );
      if (cacheResult != null) {
        yield QueryResult(
          source: QueryResultSource.cache,
          data: cacheResult,
        );
      }
    }

    try {
      yield* link.request(request).map((response) {
        QueryResult? queryResult;
        bool rereadFromCache = false;
        try {
          queryResult = mapFetchResultToQueryResult(
            response,
            options,
            source: QueryResultSource.network,
          );

          rereadFromCache = attemptCacheWriteFromResponse(
            options.policies,
            request,
            response,
            queryResult,
          );
        } catch (failure, trace) {
          // we set the source to indicate where the source of failure
          queryResult ??= QueryResult(source: QueryResultSource.network);

          queryResult.exception = coalesceErrors(
            exception: queryResult.exception,
            linkException: translateFailure(failure, trace),
          );
        }

        if (rereadFromCache) {
          // normalize results if previously written
          attempCacheRereadIntoResult(request, queryResult);
        }

        return queryResult;
      }).transform(StreamTransformer.fromHandlers(
        handleError: (err, trace, sink) => sink.add(_wrapFailure(err, trace)),
      ));
    } catch (ex, trace) {
      yield* Stream.fromIterable([_wrapFailure(ex, trace)]);
    }
  }

  Future<QueryResult> query(QueryOptions options) async {
    final result = await fetchQuery(_oneOffOpId, options);
    maybeRebroadcastQueries();

    return result;
  }

  Future<QueryResult> mutate(MutationOptions options) async {
    final result = await fetchQuery(_oneOffOpId, options);
    // once the mutation has been process successfully, execute callbacks
    // before returning the results
    final mutationCallbacks = MutationCallbackHandler(
      cache: cache,
      options: options,
      queryId: _oneOffOpId,
    );

    final callbacks = mutationCallbacks.callbacks;

    for (final callback in callbacks) {
      await callback(result);
    }

    /// wait until callbacks complete to rebroadcast
    maybeRebroadcastQueries();

    return result;
  }

  Future<QueryResult> fetchQuery(
    String queryId,
    BaseOptions options,
  ) async {
    final MultiSourceResult allResults =
        fetchQueryAsMultiSourceResult(queryId, options);
    return allResults.networkResult ?? allResults.eagerResult;
  }

  /// Wrap both the `eagerResult` and `networkResult` future in a `MultiSourceResult`
  /// if the cache policy precludes a network request, `networkResult` will be `null`
  MultiSourceResult fetchQueryAsMultiSourceResult(
    String queryId,
    BaseOptions options,
  ) {
    // create a new request to execute
    final request = options.asRequest;

    final QueryResult eagerResult = _resolveQueryEagerly(
      request,
      queryId,
      options,
    );

    // _resolveQueryEagerly handles cacheOnly,
    // so if we're loading + cacheFirst we continue to network
    return MultiSourceResult(
      eagerResult: eagerResult,
      networkResult:
          (shouldStopAtCache(options.fetchPolicy) && !eagerResult.isLoading)
              ? null
              : _resolveQueryOnNetwork(request, queryId, options),
    );
  }

  /// Resolve the query on the network,
  /// negotiating any necessary cache edits / optimistic cleanup
  Future<QueryResult> _resolveQueryOnNetwork(
    Request request,
    String queryId,
    BaseOptions options,
  ) async {
    Response response;
    QueryResult? queryResult;

    bool rereadFromCache = false;

    try {
      // execute the request through the provided link(s)
      response = await link.request(request).first;

      queryResult = mapFetchResultToQueryResult(
        response,
        options,
        source: QueryResultSource.network,
      );

      rereadFromCache = attemptCacheWriteFromResponse(
        options.policies,
        request,
        response,
        queryResult,
      );
    } catch (failure, trace) {
      // we set the source to indicate where the source of failure
      queryResult ??= QueryResult(source: QueryResultSource.network);

      queryResult.exception = coalesceErrors(
        exception: queryResult.exception,
        linkException: translateFailure(failure, trace),
      );
    }

    // cleanup optimistic results
    cache.removeOptimisticPatch(queryId);

    if (rereadFromCache) {
      // normalize results if previously written
      attempCacheRereadIntoResult(request, queryResult);
    }

    // one off operations do not have an ObservableQuery to add to
    if (queryId != _oneOffOpId) {
      addQueryResult(request, queryId, queryResult);
    }

    return queryResult;
  }

  /// Add an eager cache response to the stream if possible,
  /// based on `fetchPolicy` and `optimisticResults`
  QueryResult _resolveQueryEagerly(
    Request request,
    String queryId,
    BaseOptions options,
  ) {
    QueryResult queryResult = QueryResult.loading();

    try {
      if (options.optimisticResult != null) {
        queryResult = _getOptimisticQueryResult(
          request,
          queryId: queryId,
          optimisticResult: options.optimisticResult,
        );
      }

      // if we haven't already resolved results optimistically,
      // we attempt to resolve the from the cache
      if (shouldRespondEagerlyFromCache(options.fetchPolicy) &&
          !queryResult.isOptimistic) {
        final dynamic data = cache.readQuery(request, optimistic: false);
        // we only push an eager query with data
        if (data != null) {
          queryResult = QueryResult(
            data: data,
            source: QueryResultSource.cache,
          );
        }

        if (options.fetchPolicy == FetchPolicy.cacheOnly &&
            queryResult.isLoading) {
          queryResult = QueryResult(
            source: QueryResultSource.cache,
            exception: OperationException(
              linkException: CacheMissException(
                'Could not resolve the given request against the cache. (FetchPolicy.cacheOnly)',
                request,
              ),
            ),
          );
        }
      }
    } catch (failure, trace) {
      queryResult.exception = coalesceErrors(
        exception: queryResult.exception,
        linkException: translateFailure(failure, trace),
      );
    }

    // If not a regular eager cache resolution,
    // will either be loading, or optimistic.
    //
    // if there's an optimistic result, we add it regardless of fetchPolicy.
    // This is undefined-ish behavior/edge case, but still better than just
    // ignoring a provided optimisticResult.
    // Would probably be better to add it ignoring the cache in such cases
    //
    // one off operations do not have an ObservableQuery to add to
    if (queryId != _oneOffOpId) {
      addQueryResult(request, queryId, queryResult);
    }

    return queryResult;
  }

  /// Refetch the [ObservableQuery] referenced by [queryId],
  /// overriding any present non-network-only [FetchPolicy].
  Future<QueryResult?> refetchQuery(String queryId) {
    final WatchQueryOptions options = queries[queryId]!.options.copy();
    if (!willAlwaysExecuteOnNetwork(options.fetchPolicy)) {
      options.policies = options.policies.copyWith(
        fetch: FetchPolicy.networkOnly,
      );
    }

    // create a new request to execute
    final request = options.asRequest;

    return _resolveQueryOnNetwork(request, queryId, options);
  }

  @experimental
  Future<List<QueryResult?>> refetchSafeQueries() async {
    rebroadcastLocked = true;
    final results = await Future.wait(
      queries.values.where((q) => q.isRefetchSafe).map((q) => q.refetch()),
    );
    rebroadcastLocked = false;
    maybeRebroadcastQueries();
    return results;
  }

  ObservableQuery? getQuery(String? queryId) {
    if (queries.containsKey(queryId)) {
      return queries[queryId!];
    }

    return null;
  }

  /// Add a result to the [ObservableQuery] specified by `queryId`, if it exists.
  ///
  /// Will [maybeRebroadcastQueries] from [ObservableQuery.addResult] if the [cache] has flagged the need to.
  ///
  /// Queries are registered via [setQuery] and [watchQuery]
  void addQueryResult(
    Request request,
    String? queryId,
    QueryResult queryResult,
  ) {
    final ObservableQuery? observableQuery = getQuery(queryId);

    if (observableQuery != null && !observableQuery.controller.isClosed) {
      observableQuery.addResult(queryResult);
    }
  }

  /// Create an optimstic result for the query specified by `queryId`, if it exists
  QueryResult _getOptimisticQueryResult(
    Request request, {
    required String queryId,
    required Object? optimisticResult,
  }) {
    QueryResult queryResult = QueryResult(
      source: QueryResultSource.optimisticResult,
    );

    attemptCacheWriteFromClient(
      request,
      optimisticResult as Map<String, dynamic>?,
      queryResult,
      writeQuery: (req, data) => cache.recordOptimisticTransaction(
        (proxy) => proxy..writeQuery(req, data: data!),
        queryId,
      ),
    );

    if (!queryResult.hasException) {
      queryResult.data = cache.readQuery(
        request,
        optimistic: true,
      );
    }

    return queryResult;
  }

  /// Rebroadcast cached queries with changed underlying data if [cache.broadcastRequested] or [force].
  ///
  /// Push changed data from cache to query streams.
  /// [exclude] is used to skip a query if it was recently executed
  /// (normally the query that caused the rebroadcast)
  ///
  /// Returns whether a broadcast was executed, which depends on the state of the cache.
  /// If there are multiple in-flight cache updates, we wait until they all complete
  ///
  /// **Note on internal implementation details**:
  /// There is sometimes confusion on when this is called, but rebroadcasts are requested
  /// from every [addQueryResult] where `result.isNotLoading` as an [OnData] callback from [ObservableQuery].
  bool maybeRebroadcastQueries({ObservableQuery? exclude, bool force = false}) {
    if (rebroadcastLocked && !force) {
      return false;
    }

    final shouldBroadast = cache.shouldBroadcast(claimExecution: true);

    if (!shouldBroadast && !force) {
      return false;
    }

    for (ObservableQuery query in queries.values) {
      if (query != exclude && query.isRebroadcastSafe) {
        final cachedData = cache.readQuery(
          query.options.asRequest,
          optimistic: query.options.policies.mergeOptimisticData,
        );
        if (_cachedDataHasChangedFor(query, cachedData)) {
          query.addResult(
            mapFetchResultToQueryResult(
              Response(data: cachedData),
              query.options,
              source: QueryResultSource.cache,
            ),
            fromRebroadcast: true,
          );
        }
      }
    }
    return true;
  }

  bool _cachedDataHasChangedFor(
    ObservableQuery query,
    Map<String, dynamic>? cachedData,
  ) =>
      cachedData != null &&
      (alwaysRebroadcast || !_deepEquals(query.latestResult!.data, cachedData));

  void setQuery(ObservableQuery observableQuery) {
    queries[observableQuery.queryId] = observableQuery;
  }

  void closeQuery(ObservableQuery observableQuery, {bool fromQuery = false}) {
    if (!fromQuery) {
      observableQuery.close(fromManager: true);
    }
    queries.remove(observableQuery.queryId);
  }

  int generateQueryId() {
    final int requestId = idCounter;

    idCounter++;

    return requestId;
  }

  QueryResult mapFetchResultToQueryResult(
    Response response,
    BaseOptions options, {
    required QueryResultSource source,
  }) {
    List<GraphQLError>? errors;
    dynamic data;

    // check if there are errors and apply the error policy if so
    // in a nutshell: `ignore` swallows errors, `none` swallows data
    if (response.errors != null && response.errors!.isNotEmpty) {
      switch (options.errorPolicy) {
        case ErrorPolicy.all:
          // handle both errors and data
          errors = response.errors;
          data = response.data;
          break;
        case ErrorPolicy.ignore:
          // ignore errors
          data = response.data;
          break;
        case ErrorPolicy.none:
        default:
          // TODO not actually sure if apollo even casts graphql errors in `none` mode,
          // it's also kind of legacy
          errors = response.errors;
          break;
      }
    } else {
      data = response.data;
    }

    return QueryResult(
      data: data,
      context: response.context,
      source: source,
      exception: coalesceErrors(graphqlErrors: errors),
    );
  }
}

QueryResult _wrapFailure(dynamic ex, trace) => QueryResult(
      // we set the source to indicate where the source of failure
      source: QueryResultSource.network,
      exception: coalesceErrors(linkException: translateFailure(ex, trace)),
    );
