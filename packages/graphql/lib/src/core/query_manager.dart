import 'dart:async';

import 'package:meta/meta.dart';

import 'package:gql_exec/gql_exec.dart';
import 'package:gql_link/gql_link.dart';

import 'package:graphql/src/cache/cache.dart';
import 'package:graphql/src/core/observable_query.dart';
import 'package:graphql/src/core/query_options.dart';
import 'package:graphql/src/core/query_result.dart';
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
          (shouldStopAtCache(options.fetchPolicy) && !eagerResult.loading)
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

    try {
      // execute the request through the provided link(s)
      response = await link
          .request(
            request,
          )
          .first;

      // save the data from response to the cache
      if (response.data != null && options.fetchPolicy != FetchPolicy.noCache) {
        cache.writeQuery(request, response.data);
      }

      queryResult = mapFetchResultToQueryResult(
        response,
        options,
        source: QueryResultSource.Network,
      );
    } catch (failure) {
      // TODO: handle Link exceptions
      // TODO can we model this transformation as a link

      // we set the source to indicate where the source of failure
      queryResult ??= QueryResult(source: QueryResultSource.Network);

      queryResult.exception = coalesceErrors(
        exception: queryResult.exception,
        linkException:
            failure is LinkException ? failure : UnknownException(failure),
      );
    }

    // cleanup optimistic results
    cache.removeOptimisticPatch(queryId);
    if (options.fetchPolicy != FetchPolicy.noCache) {
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
    final String cacheKey = options.toKey();

    QueryResult queryResult = QueryResult(loading: true);

    try {
      if (options.optimisticResult != null) {
        queryResult = _getOptimisticQueryResult(
          request,
          cacheKey: cacheKey,
          optimisticResult: options.optimisticResult,
        );
      }

      // if we haven't already resolved results optimistically,
      // we attempt to resolve the from the cache
      if (shouldRespondEagerlyFromCache(options.fetchPolicy) &&
          !queryResult.optimistic) {
        final dynamic data = cache.readQuery(request, optimistic: false);
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
              linkException: CacheMissException(
                'Could not find that request in the cache. (FetchPolicy.cacheOnly)',
                cacheKey,
              ),
            ),
          );
        }
      }
    } catch (failure) {
      queryResult.exception = coalesceErrors(
        exception: queryResult.exception,
        linkException:
            failure is LinkException ? failure : UnknownException(failure),
      );
    }

    // If not a regular eager cache resolution,
    // will either be loading, or optimistic.
    //
    // if there's an optimistic result, we add it regardless of fetchPolicy
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
  ///
  /// Queries are registered via [setQuery] and [watchQuery]
  void addQueryResult(
    Request request,
    String queryId,
    QueryResult queryResult, {
    bool writeToCache = false,
  }) {
    final ObservableQuery observableQuery = getQuery(queryId);
    if (writeToCache) {
      cache.writeQuery(
        request,
        queryResult.data,
      );
    }

    if (observableQuery != null && !observableQuery.controller.isClosed) {
      observableQuery.addResult(queryResult);
    }
  }

  /// Create an optimstic result for the query specified by `queryId`, if it exists
  QueryResult _getOptimisticQueryResult(
    Request request, {
    @required String cacheKey,
    @required Object optimisticResult,
  }) {
    cache.writeQuery(request, optimisticResult);

    final QueryResult queryResult = QueryResult(
      data: cache.readQuery(
        request,
        optimistic: true,
      ),
      source: QueryResultSource.OptimisticResult,
    );
    return queryResult;
  }

  /// Remove the optimistic patch for `cacheKey`, if any
  void cleanupOptimisticResults(String cacheKey) {
    cache.removeOptimisticPatch(cacheKey);
  }

  /// Push changed data from cache to query streams
  ///
  /// rebroadcast queries inherit `optimistic`
  /// from the triggering state-change
  // TODO  ^ no longer true. I would like to recoup the entity-wise
  // TODO cache state optimistic awareness
  void rebroadcastQueries() {
    for (ObservableQuery query in queries.values) {
      if (query.isRebroadcastSafe) {
        // TODO use queryId everywhere or nah
        final dynamic cachedData =
            cache.readQuery(query.options.asRequest, optimistic: true);
        if (cachedData != null) {
          query.addResult(
            mapFetchResultToQueryResult(
              Response(data: cachedData),
              query.options,
              // TODO maybe entirely wrong
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
