import 'dart:async';

import 'package:meta/meta.dart';

import 'package:graphql/src/core/query_options.dart';
import 'package:graphql/src/core/query_result.dart';
import 'package:graphql/src/core/graphql_error.dart';
import 'package:graphql/src/core/observable_query.dart';

import 'package:graphql/src/scheduler/scheduler.dart';

import 'package:graphql/src/link/link.dart';
import 'package:graphql/src/link/operation.dart';
import 'package:graphql/src/link/fetch_result.dart';

import 'package:graphql/src/cache/cache.dart';
import 'package:graphql/src/cache/normalized_in_memory.dart'
    show NormalizedInMemoryCache;
import 'package:graphql/src/cache/optimistic.dart' show OptimisticCache;

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
    if (options.document == null) {
      throw Exception(
        'document option is required. You must specify your GraphQL document in the query options.',
      );
    }

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
    return fetchQuery('0', options);
  }

  Future<QueryResult> fetchQuery(
    String queryId,
    BaseOptions options,
  ) async {
    // create a new operation to fetch
    final Operation operation = Operation.fromOptions(options);

    if (options.optimisticResult != null) {
      addOptimisticQueryResult(
        queryId,
        cacheKey: operation.toKey(),
        optimisticResult: options.optimisticResult,
      );
    }

    FetchResult fetchResult;
    QueryResult queryResult;

    try {
      if (options.context != null) {
        operation.setContext(options.context);
      }
      queryResult = _addEagerCacheResult(
        queryId,
        operation.toKey(),
        options.fetchPolicy,
      );

      if (shouldStopAtCache(options.fetchPolicy) && queryResult != null) {
        return queryResult;
      }

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

      if (fetchResult.data == null &&
          fetchResult.errors == null &&
          (options.fetchPolicy == FetchPolicy.noCache ||
              options.fetchPolicy == FetchPolicy.networkOnly)) {
        throw Exception(
          'Could not resolve that operation on the network. (${options.fetchPolicy.toString()})',
        );
      }

      queryResult = mapFetchResultToQueryResult(
        fetchResult,
        options,
        loading: false,
        optimistic: false,
      );
    } catch (error) {
      queryResult ??= QueryResult(
        loading: false,
        optimistic: false,
      );
      queryResult.addError(_attemptToWrapError(error));
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

  void refetchQuery(String queryId) {
    final WatchQueryOptions options = queries[queryId].options;
    fetchQuery(queryId, options);
  }

  ObservableQuery getQuery(String queryId) {
    if (queries.containsKey(queryId)) {
      return queries[queryId];
    }

    return null;
  }

  GraphQLError _attemptToWrapError(dynamic error) {
    String errorMessage;

    // not all errors thrown above are GraphQL errors,
    // so try/catch to avoid "could not access message"
    try {
      errorMessage = error.message as String;
    } catch (e) {
      throw error;
    }

    return GraphQLError(
      message: errorMessage,
    );
  }

  /// Add a result to the query specified by `queryId`, if it exists
  void addQueryResult(String queryId, QueryResult queryResult) {
    final ObservableQuery observableQuery = getQuery(queryId);
    if (observableQuery != null && !observableQuery.controller.isClosed) {
      observableQuery.addResult(queryResult);
    }
  }

  // TODO what should the relationship to optimism be here
  // TODO we should switch to quiver Optionals
  /// Add an eager cache response to the stream if possible based on `fetchPolicy`
  QueryResult _addEagerCacheResult(
      String queryId, String cacheKey, FetchPolicy fetchPolicy) {
    if (shouldRespondEagerlyFromCache(fetchPolicy)) {
      final dynamic cachedData = cache.read(cacheKey);

      if (cachedData != null) {
        // we're rebroadcasting from cache,
        // so don't override optimism
        final QueryResult queryResult = QueryResult(
          data: cachedData,
          loading: false,
        );

        addQueryResult(queryId, queryResult);

        return queryResult;
      }

      if (fetchPolicy == FetchPolicy.cacheOnly) {
        throw Exception(
          'Could not find that operation in the cache. (${fetchPolicy.toString()})',
        );
      }
    }
    return null;
  }

  /// Add an optimstic result to the query specified by `queryId`, if it exists
  void addOptimisticQueryResult(
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
      loading: false,
      optimistic: true,
    );
    addQueryResult(queryId, queryResult);
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
    bool loading,
    bool optimistic = false,
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
      errors: errors,
      loading: loading,
      optimistic: optimistic,
    );
  }

  List<GraphQLError> _errorsFromResult(FetchResult fetchResult) =>
      List<GraphQLError>.from(fetchResult.errors.map<GraphQLError>(
        (dynamic rawError) => GraphQLError.fromJSON(rawError),
      ));
}
