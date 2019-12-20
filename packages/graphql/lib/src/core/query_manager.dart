import 'dart:async';

import 'package:graphql/src/cache/cache.dart';
import 'package:graphql/src/cache/normalized_in_memory.dart'
    show NormalizedInMemoryCache;
import 'package:graphql/src/cache/optimistic.dart' show OptimisticCache;
import 'package:graphql/src/core/observable_query.dart';
import 'package:graphql/src/core/query_options.dart';
import 'package:graphql/src/core/query_result.dart';
import 'package:graphql/src/exceptions/exceptions.dart';
import 'package:graphql/src/link/fetch_result.dart';
import 'package:graphql/src/link/link.dart';
import 'package:graphql/src/link/operation.dart';
import 'package:graphql/src/scheduler/scheduler.dart';
import 'package:meta/meta.dart';

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
  final Cache cache;

  QueryScheduler scheduler;
  int idCounter = 1;
  Map<String, ObservableQuery> queries = <String, ObservableQuery>{};

  ObservableQuery watchQuery(WatchQueryOptions options) {
    final ObservableQuery observableQuery = ObservableQuery(
      queryManager: this,
      options: options,
    );

    setQuery(observableQuery);

    return observableQuery;
  }

  Future<QueryResult> query(QueryOptions options) {
    return fetchQuery('0', options);
  }

  Future<QueryResult> mutate(MutationOptions options) {
    return fetchQuery('0', options).then((result) async {
      // not sure why query id is '0', may be needs improvements
      // once the mutation has been process successfully, execute callbacks
      // before returning the results
      final mutationCallbacks = MutationCallbacks(
        cache: cache,
        options: options,
        queryId: '0',
      );

      final callbacks = mutationCallbacks.callbacks;

      for (final callback in callbacks) {
        await callback(result);
      }

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
    final QueryResult eagerResult = _resolveQueryEagerly(
      queryId,
      options,
    );

    // _resolveQueryEagerly handles cacheOnly,
    // so if we're loading + cacheFirst we continue to network
    return MultiSourceResult(
      eagerResult: eagerResult,
      networkResult:
          (shouldStopAtCache(options.fetchPolicy) && !eagerResult.loading)
              ? null
              : _resolveQueryOnNetwork(queryId, options),
    );
  }

  /// Resolve the query on the network,
  /// negotiating any necessary cache edits / optimistic cleanup
  Future<QueryResult> _resolveQueryOnNetwork(
    String queryId,
    BaseOptions options,
  ) async {
    // create a new operation to fetch
    final Operation operation = Operation.fromOptions(options)
      ..setContext(options.context);

    FetchResult fetchResult;
    QueryResult queryResult;

    try {
      // execute the operation through the provided link(s)
      fetchResult = await execute(
        link: link,
        operation: operation,
      ).first;

      // save the data from fetchResult to the cache
      if (fetchResult.data != null &&
          options.fetchPolicy != FetchPolicy.noCache) {
        cache.write(
          operation.toKey(),
          fetchResult.data,
        );
      }

      queryResult = mapFetchResultToQueryResult(
        fetchResult,
        options,
        source: QueryResultSource.Network,
      );
    } catch (failure) {
      // we set the source to indicate where the source of failure
      queryResult ??= QueryResult(source: QueryResultSource.Network);

      queryResult.exception = coalesceErrors(
        exception: queryResult.exception,
        clientException: translateFailure(failure),
      );
    }

    // cleanup optimistic results
    cleanupOptimisticResults(queryId);
    if (options.fetchPolicy != FetchPolicy.noCache &&
        cache is NormalizedInMemoryCache) {
      // normalize results if previously written
      queryResult.data = cache.read(operation.toKey());
    }

    addQueryResult(queryId, queryResult);

    return queryResult;
  }

  /// Add an eager cache response to the stream if possible,
  /// based on `fetchPolicy` and `optimisticResults`
  QueryResult _resolveQueryEagerly(
    String queryId,
    BaseOptions options,
  ) {
    final String cacheKey = options.toKey();

    QueryResult queryResult = QueryResult(loading: true);

    try {
      if (options.optimisticResult != null) {
        queryResult = _getOptimisticQueryResult(
          queryId,
          cacheKey: cacheKey,
          optimisticResult: options.optimisticResult,
        );
      }

      // if we haven't already resolved results optimistically,
      // we attempt to resolve the from the cache
      if (shouldRespondEagerlyFromCache(options.fetchPolicy) &&
          !queryResult.optimistic) {
        final dynamic data = cache.read(cacheKey);
        // we only push an eager query with data
        if (data != null) {
          queryResult = QueryResult(
            data: data,
            source: QueryResultSource.Cache,
          );
        }

        if (options.fetchPolicy == FetchPolicy.cacheOnly &&
            queryResult.loading) {
          queryResult = QueryResult(
            source: QueryResultSource.Cache,
            exception: OperationException(
              clientException: CacheMissException(
                'Could not find that operation in the cache. (FetchPolicy.cacheOnly)',
                cacheKey,
              ),
            ),
          );
        }
      }
    } catch (failure) {
      queryResult.exception = coalesceErrors(
        exception: queryResult.exception,
        clientException: translateFailure(failure),
      );
    }

    // If not a regular eager cache resolution,
    // will either be loading, or optimistic.
    //
    // if there's an optimistic result, we add it regardless of fetchPolicy
    // This is undefined-ish behavior/edge case, but still better than just
    // ignoring a provided optimisticResult.
    // Would probably be better to add it ignoring the cache in such cases
    addQueryResult(queryId, queryResult);
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

  /// Add a result to the query specified by `queryId`, if it exists
  void addQueryResult(
    String queryId,
    QueryResult queryResult, {
    bool writeToCache = false,
  }) {
    final ObservableQuery observableQuery = getQuery(queryId);
    if (writeToCache) {
      cache.write(
        observableQuery.options.toKey(),
        queryResult.data,
      );
    }

    if (observableQuery != null && !observableQuery.controller.isClosed) {
      observableQuery.addResult(queryResult);
    }
  }

  /// Create an optimstic result for the query specified by `queryId`, if it exists
  QueryResult _getOptimisticQueryResult(
    String queryId, {
    @required String cacheKey,
    @required Object optimisticResult,
  }) {
    assert(cache is OptimisticCache,
        "can't optimisticly update non-optimistic cache");

    (cache as OptimisticCache).addOptimisiticPatch(
        queryId, (Cache cache) => cache..write(cacheKey, optimisticResult));

    final QueryResult queryResult = QueryResult(
      data: cache.read(cacheKey),
      source: QueryResultSource.OptimisticResult,
    );
    return queryResult;
  }

  /// Remove the optimistic patch for `cacheKey`, if any
  void cleanupOptimisticResults(String cacheKey) {
    if (cache is OptimisticCache) {
      (cache as OptimisticCache).removeOptimisticPatch(cacheKey);
    }
  }

  /// Push changed data from cache to query streams
  ///
  /// rebroadcast queries inherit `optimistic`
  /// from the triggering state-change
  void rebroadcastQueries() {
    for (ObservableQuery query in queries.values) {
      if (query.isRebroadcastSafe) {
        final dynamic cachedData = cache.read(query.options.toKey());
        if (cachedData != null) {
          query.addResult(
            mapFetchResultToQueryResult(
              FetchResult(data: cachedData),
              query.options,
              source: QueryResultSource.Cache,
            ),
          );
        }
      }
    }
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
    FetchResult fetchResult,
    BaseOptions options, {
    @required QueryResultSource source,
  }) {
    List<GraphQLError> errors;
    dynamic data;

    // check if there are errors and apply the error policy if so
    // in a nutshell: `ignore` swallows errors, `none` swallows data
    if (fetchResult.errors != null && fetchResult.errors.isNotEmpty) {
      switch (options.errorPolicy) {
        case ErrorPolicy.all:
          // handle both errors and data
          errors = _errorsFromResult(fetchResult);
          data = fetchResult.data;
          break;
        case ErrorPolicy.ignore:
          // ignore errors
          data = fetchResult.data;
          break;
        case ErrorPolicy.none:
        default:
          // TODO not actually sure if apollo even casts graphql errors in `none` mode,
          // it's also kind of legacy
          errors = _errorsFromResult(fetchResult);
          break;
      }
    } else {
      data = fetchResult.data;
    }

    return QueryResult(
      data: data,
      source: source,
      exception: coalesceErrors(graphqlErrors: errors),
    );
  }

  List<GraphQLError> _errorsFromResult(FetchResult fetchResult) =>
      List<GraphQLError>.from(fetchResult.errors.map<GraphQLError>(
        (dynamic rawError) => GraphQLError.fromJSON(rawError),
      ));
}
