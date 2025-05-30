import 'dart:async';

import 'package:graphql/src/utilities/helpers.dart';
import 'package:graphql/src/utilities/response.dart';
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

typedef DeepEqualsFn = bool Function(dynamic a, dynamic b);
typedef AsyncDeepEqualsFn = Future<bool> Function(dynamic a, dynamic b);

/// The equality function used for comparing cached and new data
/// in synchronous contexts like operator overrides or custom logic.
///
/// You can alternatively provide [optimizedDeepEquals] for a faster
/// equality check, or provide your own via the [GqlClient] constructor.
DeepEqualsFn gqlDeepEquals = const DeepCollectionEquality().equals;

/// The async equality function used for comparing cached and new data
/// during asynchronous operations like rebroadcast checks.
///
/// Can be provided via the constructor for custom or isolate-based comparison logic.
AsyncDeepEqualsFn gqlAsyncDeepEquals =
    (dynamic a, dynamic b) async => gqlDeepEquals(a, b);

class QueryManager {
  QueryManager({
    required this.link,
    required this.cache,
    this.alwaysRebroadcast = false,
    DeepEqualsFn? deepEquals,
    AsyncDeepEqualsFn? asyncDeepEquals,
    bool deduplicatePollers = false,
    this.requestTimeout = const Duration(seconds: 5),
  }) {
    scheduler = QueryScheduler(
      queryManager: this,
      deduplicatePollers: deduplicatePollers,
    );
    if (deepEquals != null) {
      gqlDeepEquals = deepEquals;
    }
    if (asyncDeepEquals != null) {
      gqlAsyncDeepEquals = asyncDeepEquals;
    }
  }

  final Link link;
  final GraphQLCache cache;

  /// Whether to skip deep equality checks in [maybeRebroadcastQueriesAsync]
  final bool alwaysRebroadcast;

  /// The timeout for resolving a query
  final Duration? requestTimeout;

  QueryScheduler? scheduler;
  static final _oneOffOpId = '0';
  int idCounter = 1;

  /// [ObservableQuery] registry
  Map<String, ObservableQuery<Object?>> queries =
      <String, ObservableQuery<Object?>>{};

  /// prevents rebroadcasting for some intensive bulk operation like [refetchSafeQueries]
  bool rebroadcastLocked = false;

  ObservableQuery<TParsed> watchQuery<TParsed>(
      WatchQueryOptions<TParsed> options) {
    final ObservableQuery<TParsed> observableQuery = ObservableQuery<TParsed>(
      queryManager: this,
      options: options,
    );

    setQuery(observableQuery);

    return observableQuery;
  }

  Stream<QueryResult<TParsed>> subscribe<TParsed>(
      SubscriptionOptions<TParsed> options) async* {
    assert(
      options.fetchPolicy != FetchPolicy.cacheOnly,
      "Cannot subscribe with FetchPolicy.cacheOnly: $options",
    );
    final request = options.asRequest;

    // Add optimistic or cache-based result to the stream if any
    if (options.optimisticResult != null) {
      // TODO optimisticResults for streams just skip the cache for now
      yield QueryResult.optimistic(
        data: options.optimisticResult as Map<String, dynamic>?,
        options: options,
      );
    } else if (shouldRespondEagerlyFromCache(options.fetchPolicy)) {
      final cacheResult = cache.readQuery(
        request,
        optimistic: options.policies.mergeOptimisticData,
      );
      if (cacheResult != null) {
        yield QueryResult(
          options: options,
          source: QueryResultSource.cache,
          data: cacheResult,
        );
      }
    }

    try {
      yield* link
          .request(request)
          .map((response) {
            QueryResult<TParsed>? queryResult;
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
              queryResult ??= QueryResult(
                options: options,
                source: QueryResultSource.network,
              );

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
          })
          .transform<QueryResult<TParsed>>(StreamTransformer.fromHandlers(
            handleError: (err, trace, sink) => sink.add(_wrapFailure(
              options,
              err,
              trace,
            )),
          ))
          .map((QueryResult<TParsed> queryResult) {
            maybeRebroadcastQueriesAsync();
            return queryResult;
          });
    } catch (ex, trace) {
      yield* Stream.fromIterable([
        _wrapFailure(
          options,
          ex,
          trace,
        )
      ]);
    }
  }

  Future<QueryResult<TParsed>> query<TParsed>(
      QueryOptions<TParsed> options) async {
    final results = await fetchQueryAsMultiSourceResult(_oneOffOpId, options);
    final eagerResult = results.eagerResult;
    final networkResult = results.networkResult;
    if (options.fetchPolicy != FetchPolicy.cacheAndNetwork ||
        eagerResult.isLoading) {
      final result = networkResult ?? eagerResult;
      await result;
      maybeRebroadcastQueriesAsync();
      return result;
    }
    maybeRebroadcastQueriesAsync();
    if (networkResult is Future<QueryResult<TParsed>>) {
      networkResult.then((value) => maybeRebroadcastQueriesAsync());
    }
    return eagerResult;
  }

  Future<QueryResult<TParsed>> mutate<TParsed>(
      MutationOptions<TParsed> options) async {
    final result = await fetchQuery(_oneOffOpId, options);
    // once the mutation has been process successfully, execute callbacks
    // before returning the results
    final mutationCallbacks = MutationCallbackHandler<TParsed>(
      cache: cache,
      options: options,
      queryId: _oneOffOpId,
    );

    final callbacks = mutationCallbacks.callbacks;

    for (final callback in callbacks) {
      await callback(result);
    }

    /// wait until callbacks complete to rebroadcast
    maybeRebroadcastQueriesAsync();

    return result;
  }

  Future<QueryResult<TParsed>> fetchQuery<TParsed>(
    String queryId,
    BaseOptions<TParsed> options,
  ) async {
    final MultiSourceResult<TParsed> allResults =
        fetchQueryAsMultiSourceResult(queryId, options);
    return allResults.networkResult ?? allResults.eagerResult;
  }

  /// Wrap both the `eagerResult` and `networkResult` future in a `MultiSourceResult`
  /// if the cache policy precludes a network request, `networkResult` will be `null`
  MultiSourceResult<TParsed> fetchQueryAsMultiSourceResult<TParsed>(
    String queryId,
    BaseOptions<TParsed> options,
  ) {
    // create a new request to execute
    final request = options.asRequest;

    final QueryResult<TParsed> eagerResult = _resolveQueryEagerly(
      request,
      queryId,
      options,
    );

    // _resolveQueryEagerly handles cacheOnly,
    // so if we're loading + cacheFirst we continue to network
    return MultiSourceResult(
      options: options,
      eagerResult: eagerResult,
      networkResult:
          (shouldStopAtCache(options.fetchPolicy) && !eagerResult.isLoading)
              ? null
              : _resolveQueryOnNetwork(request, queryId, options),
    );
  }

  /// Resolve the query on the network,
  /// negotiating any necessary cache edits / optimistic cleanup
  Future<QueryResult<TParsed>> _resolveQueryOnNetwork<TParsed>(
    Request request,
    String queryId,
    BaseOptions<TParsed> options,
  ) async {
    Response response;
    QueryResult<TParsed>? queryResult;

    bool rereadFromCache = false;

    try {
      // execute the request through the provided link(s)
      Stream<Response> responseStream = link.request(request);

      // Resolve the request timeout by first checking the options of this specific request,
      // then the manager level requestTimeout.
      // Only apply the timeout if it is non-null.
      final timeout = options.queryRequestTimeout ?? this.requestTimeout;
      if (timeout case final Duration timeout) {
        responseStream = responseStream.timeout(timeout);
      }
      response = await responseStream.first;

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
      queryResult ??= QueryResult(
        options: options,
        source: QueryResultSource.network,
      );

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
  QueryResult<TParsed> _resolveQueryEagerly<TParsed>(
    Request request,
    String queryId,
    BaseOptions<TParsed> options,
  ) {
    QueryResult<TParsed> queryResult = QueryResult.loading(options: options);

    try {
      if (options.optimisticResult != null) {
        queryResult = _getOptimisticQueryResult(
          request,
          queryId: queryId,
          optimisticResult: options.optimisticResult,
          options: options,
        );
      }

      // if we haven't already resolved results optimistically,
      // we attempt to resolve the from the cache
      if (shouldRespondEagerlyFromCache(options.fetchPolicy) &&
          !queryResult.isOptimistic) {
        final latestResult = _getQueryResultByRequest<TParsed>(request);
        if (latestResult != null && latestResult.data != null) {
          // we have a result already cached + deserialized for this request
          // so we reuse it.
          // latest result won't be for loading, it must contain data
          queryResult = latestResult.copyWith(
            source: QueryResultSource.cache,
          );
        } else {
          // otherwise, we try to find the query in cache (which will require
          // deserialization)
          final data = cache.readQuery(request, optimistic: false);
          // we only push an eager query with data
          if (data != null) {
            queryResult = QueryResult(
              options: options,
              data: data,
              source: QueryResultSource.cache,
            );
          }
        }

        if (options.fetchPolicy == FetchPolicy.cacheOnly &&
            queryResult.isLoading) {
          queryResult = QueryResult(
            options: options,
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

  /// If a request already has a result associated with it in cache (as
  /// determined by [ObservableQuery.latestResult]), we can return it without
  /// needing to denormalize + parse again.
  QueryResult<TParsed>? _getQueryResultByRequest<TParsed>(Request request) {
    for (final query in queries.values) {
      if (query.options.asRequest == request) {
        return query.latestResult as QueryResult<TParsed>?;
      }
    }
    return null;
  }

  /// Refetch the [ObservableQuery] referenced by [queryId],
  /// overriding any present non-network-only [FetchPolicy].
  Future<QueryResult<TParsed>?> refetchQuery<TParsed>(String queryId) {
    var options = getQuery<TParsed>(queryId)!.options;
    if (!willAlwaysExecuteOnNetwork(options.fetchPolicy)) {
      options = options.copyWithFetchPolicy(FetchPolicy.networkOnly);
    }

    // create a new request to execute
    final request = options.asRequest;

    return _resolveQueryOnNetwork(request, queryId, options);
  }

  @experimental
  Future<List<QueryResult<Object?>?>> refetchSafeQueries() async {
    rebroadcastLocked = true;
    final queriesSnapshot = List.of(queries.values);
    final results = await Future.wait(
      queriesSnapshot.where((q) => q.isRefetchSafe).map((q) => q.refetch()),
    );
    rebroadcastLocked = false;
    maybeRebroadcastQueriesAsync();
    return results;
  }

  ObservableQuery<TParsed>? getQuery<TParsed>(final String? queryId) {
    if (!queries.containsKey(queryId) || queryId == null) {
      return null;
    }
    final query = queries[queryId];
    if (query is ObservableQuery<TParsed>) {
      return query;
    }
    return null;
  }

  /// Add a result to the [ObservableQuery] specified by `queryId`, if it exists.
  ///
  /// Will [maybeRebroadcastQueriesAsync] from [ObservableQuery.addResult] if the [cache] has flagged the need to.
  ///
  /// Queries are registered via [setQuery] and [watchQuery]
  void addQueryResult<TParsed>(
    Request request,
    String? queryId,
    QueryResult<TParsed> queryResult, {
    bool fromRebroadcast = false,
  }) {
    final observableQuery = getQuery<TParsed>(queryId);

    if (observableQuery != null && !observableQuery.controller.isClosed) {
      observableQuery.addResult(queryResult, fromRebroadcast: fromRebroadcast);
    }
  }

  /// Create an optimistic result for the query specified by `queryId`, if it exists
  QueryResult<TParsed> _getOptimisticQueryResult<TParsed>(
    Request request, {
    required String queryId,
    required Object? optimisticResult,
    required BaseOptions<TParsed> options,
  }) {
    QueryResult<TParsed> queryResult = QueryResult(
      options: options,
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
  Future<bool> maybeRebroadcastQueriesAsync({
    ObservableQuery<Object?>? exclude,
    bool force = false,
  }) async {
    if (rebroadcastLocked && !force) {
      return false;
    }

    final shouldBroadcast = cache.shouldBroadcast(claimExecution: true);

    if (!shouldBroadcast && !force) {
      return false;
    }

    // If two ObservableQueries are backed by the same [Request], we only need
    // to [readQuery] for it once.
    final Map<Request, QueryResult<Object?>> diffQueryResultCache = {};
    final Map<Request, bool> ignoreQueryResults = {};

    final List<ObservableQuery<Object?>> queriesSnapshot =
        List.of(queries.values);

    for (final query in queriesSnapshot) {
      final Request request = query.options.asRequest;
      final cachedQueryResult = diffQueryResultCache[request];
      if (query == exclude || !query.isRebroadcastSafe) {
        continue;
      }
      if (cachedQueryResult != null) {
        // We've already done the diff and denormalized, emit to the observable
        addQueryResult(
          request,
          query.queryId,
          cachedQueryResult,
          fromRebroadcast: true,
        );
      } else if (ignoreQueryResults.containsKey(request)) {
        // We've already seen this one and don't need to notify
        continue;
      } else {
        // We haven't seen this one yet, denormalize from cache and diff
        final cachedData = cache.readQuery(
          query.options.asRequest,
          optimistic: query.options.policies.mergeOptimisticData,
        );
        if (await _cachedDataHasChangedForAsync(query, cachedData)) {
          // The data has changed
          final queryResult = QueryResult(
            data: cachedData,
            options: query.options,
            source: QueryResultSource.cache,
          );
          diffQueryResultCache[request] = queryResult;
          addQueryResult(
            request,
            query.queryId,
            queryResult,
            fromRebroadcast: true,
          );
        } else {
          ignoreQueryResults[request] = true;
        }
      }
    }
    return true;
  }

  Future<bool> _cachedDataHasChangedForAsync(
    ObservableQuery<Object?> query,
    Map<String, dynamic>? cachedData,
  ) async {
    if (cachedData == null || query.latestResult == null) return false;
    if (alwaysRebroadcast) return true;

    final isEqual = await gqlAsyncDeepEquals(
      query.latestResult!.data,
      cachedData,
    );
    return !isEqual;
  }

  void setQuery(ObservableQuery<Object?> observableQuery) {
    queries[observableQuery.queryId] = observableQuery;
  }

  void closeQuery(ObservableQuery<Object?> observableQuery,
      {bool fromQuery = false}) {
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
}

QueryResult<TParsed> _wrapFailure<TParsed>(
  BaseOptions<TParsed> options,
  Object ex,
  StackTrace trace,
) =>
    QueryResult(
      options: options,
      // we set the source to indicate where the source of failure
      source: QueryResultSource.network,
      exception: coalesceErrors(linkException: translateFailure(ex, trace)),
    );
