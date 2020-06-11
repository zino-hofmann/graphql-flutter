import 'dart:async';

import 'package:meta/meta.dart';

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

class QueryManager {
  QueryManager({
    @required this.link,
    @required this.cache,
  }) {
    scheduler = QueryScheduler(
      queryManager: this,
    );
  }

  final Link link;
  final GraphQLCache cache;

  QueryScheduler scheduler;
  int idCounter = 1;

  /// [ObservableQuery] registry
  Map<String, ObservableQuery> queries = <String, ObservableQuery>{};

  ObservableQuery watchQuery(WatchQueryOptions options) {
    final ObservableQuery observableQuery = ObservableQuery(
      queryManager: this,
      options: options,
    );

    setQuery(observableQuery);

    return observableQuery;
  }

  Stream<QueryResult> subscribe(SubscriptionOptions options) async* {
    final request = options.asRequest;

    // Add optimistic or cache-based result to the stream if any
    if (options.optimisticResult != null) {
      // TODO optimisticResults for streams just skip the cache for now
      yield QueryResult.optimistic(data: options.optimisticResult);
    } else if (options.fetchPolicy != FetchPolicy.noCache) {
      final cacheResult = cache.readQuery(request, optimistic: true);
      if (cacheResult != null) {
        yield QueryResult(
          source: QueryResultSource.cache,
          data: options.optimisticResult,
        );
      }
    }

    yield* link.request(request).map((response) {
      QueryResult queryResult;
      try {
        if (response.data != null &&
            options.fetchPolicy != FetchPolicy.noCache) {
          cache.writeQuery(request, data: response.data);
        }
        queryResult = mapFetchResultToQueryResult(
          response,
          options,
          source: QueryResultSource.network,
        );
      } catch (failure) {
        // we set the source to indicate where the source of failure
        queryResult ??= QueryResult(source: QueryResultSource.network);

        queryResult.exception = coalesceErrors(
          exception: queryResult.exception,
          linkException: translateFailure(failure),
        );
      }

      if (options.fetchPolicy != FetchPolicy.noCache) {
        // normalize results if previously written
        queryResult.data = cache.readQuery(request);
      }

      return queryResult;
    });
  }

  Future<QueryResult> query(QueryOptions options) => fetchQuery('0', options);

  Future<QueryResult> mutate(MutationOptions options) {
    return fetchQuery('0', options).then((result) async {
      // not sure why query id is '0', may be needs improvements
      // once the mutation has been process successfully, execute callbacks
      // before returning the results
      final mutationCallbacks = MutationCallbackHandler(
        cache: cache,
        options: options,
        queryId: '0',
      );

      final callbacks = mutationCallbacks.callbacks;

      for (final callback in callbacks) {
        await callback(result);
      }

      maybeRebroadcastQueries();

      return result;
    });
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
    QueryResult queryResult;

    final writeToCache = options.fetchPolicy != FetchPolicy.noCache;

    try {
      // execute the request through the provided link(s)
      response = await link.request(request).first;

      // save the data from response to the cache
      if (response.data != null && writeToCache) {
        await cache.writeQuery(request, data: response.data);
      }

      queryResult = mapFetchResultToQueryResult(
        response,
        options,
        source: QueryResultSource.network,
      );
    } catch (failure) {
      // we set the source to indicate where the source of failure
      queryResult ??= QueryResult(source: QueryResultSource.network);

      queryResult.exception = coalesceErrors(
        exception: queryResult.exception,
        linkException: translateFailure(failure),
      );
    }

    // cleanup optimistic results
    cache.removeOptimisticPatch(queryId);

    if (writeToCache) {
      // normalize results if previously written
      queryResult.data = cache.readQuery(request);
    }

    addQueryResult(request, queryId, queryResult);

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
    } catch (failure) {
      queryResult.exception = coalesceErrors(
        exception: queryResult.exception,
        linkException: translateFailure(failure),
      );
    }

    // If not a regular eager cache resolution,
    // will either be loading, or optimistic.
    //
    // if there's an optimistic result, we add it regardless of fetchPolicy.
    // This is undefined-ish behavior/edge case, but still better than just
    // ignoring a provided optimisticResult.
    // Would probably be better to add it ignoring the cache in such cases
    addQueryResult(request, queryId, queryResult);

    return queryResult;
  }

  Future<QueryResult> refetchQuery(String queryId) {
    final WatchQueryOptions options = queries[queryId].options;
    return fetchQuery(queryId, options);
  }

  ObservableQuery getQuery(String queryId) {
    if (queries.containsKey(queryId)) {
      return queries[queryId];
    }

    return null;
  }

  /// Add a result to the [ObservableQuery] specified by `queryId`, if it exists
  /// Will [maybeRebroadcastQueries] from [addResult] if the cache has flagged the need to
  ///
  /// Queries are registered via [setQuery] and [watchQuery]
  void addQueryResult(
    Request request,
    String queryId,
    QueryResult queryResult, {
    bool writeToCache = false,
  }) {
    if (writeToCache) {
      cache.writeQuery(
        request,
        data: queryResult.data,
      );
    }

    final ObservableQuery observableQuery = getQuery(queryId);

    if (observableQuery != null && !observableQuery.controller.isClosed) {
      observableQuery.addResult(queryResult);
    }
  }

  /// Create an optimstic result for the query specified by `queryId`, if it exists
  QueryResult _getOptimisticQueryResult(
    Request request, {
    @required String queryId,
    @required Object optimisticResult,
  }) {
    cache.recordOptimisticTransaction(
      (proxy) => proxy..writeQuery(request, data: optimisticResult),
      queryId,
    );

    final QueryResult queryResult = QueryResult(
      data: cache.readQuery(
        request,
        optimistic: true,
      ),
      source: QueryResultSource.optimisticResult,
    );

    return queryResult;
  }

  /// Push changed data from cache to query streams.
  /// [exclude] is used to skip a query if it was recently executed
  /// (normally the query that caused the rebroadcast)
  ///
  /// Returns whether a broadcast was executed, which depends on the state of the cache.
  /// If there are multiple in-flight cache updates, we wait until they all complete
  bool maybeRebroadcastQueries({ObservableQuery exclude}) {
    final shouldBroadast = cache.shouldBroadcast(claimExecution: true);

    if (!shouldBroadast) {
      return false;
    }

    for (ObservableQuery query in queries.values) {
      if (query != exclude && query.isRebroadcastSafe) {
        final dynamic cachedData = cache.readQuery(
          query.options.asRequest,
          optimistic: true,
        );
        if (cachedData != null) {
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
    @required QueryResultSource source,
  }) {
    List<GraphQLError> errors;
    dynamic data;

    // check if there are errors and apply the error policy if so
    // in a nutshell: `ignore` swallows errors, `none` swallows data
    if (response.errors != null && response.errors.isNotEmpty) {
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
      source: source,
      exception: coalesceErrors(graphqlErrors: errors),
    );
  }
}
