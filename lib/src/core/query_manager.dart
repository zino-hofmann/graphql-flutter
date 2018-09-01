import 'dart:async';

import 'package:meta/meta.dart';

import 'package:graphql_flutter/src/core/query_options.dart';
import 'package:graphql_flutter/src/core/query_result.dart';
import 'package:graphql_flutter/src/core/graphql_error.dart';
import 'package:graphql_flutter/src/core/observable_query.dart';

import 'package:graphql_flutter/src/scheduler/scheduler.dart';

import 'package:graphql_flutter/src/link/link.dart';
import 'package:graphql_flutter/src/link/operation.dart';
import 'package:graphql_flutter/src/link/fetch_result.dart';

class QueryManager {
  final Link link;

  QueryScheduler scheduler;
  int idCounter = 1;
  Map<String, ObservableQuery> queries = Map();

  QueryManager({
    @required this.link,
  }) {
    scheduler = QueryScheduler(
      queryManager: this,
    );
  }

  ObservableQuery watchQuery(WatchQueryOptions options) {
    if (options.document == null) {
      throw Exception(
        'document option is required. You must specify your GraphQL document in the query options.',
      );
    }

    ObservableQuery observableQuery = ObservableQuery(
      queryManager: this,
      options: options,
    );

    setQuery(observableQuery);

    return observableQuery;
  }

  Future<QueryResult> query(QueryOptions options) async {
    if (options.document == null) {
      throw Exception(
        'document option is required. You must specify your GraphQL document in the query options.',
      );
    }

    return fetchQuery(options);
  }

  Future<QueryResult> mutate(MutationOptions options) {
    if (options.document == null) {
      throw Exception(
        'document option is required. You must specify your GraphQL document in the mutaion options.',
      );
    }

    return fetchQuery(options);
  }

  Future<QueryResult> fetchQuery(BaseOptions options) async {
    // create a new operation to fetch
    Operation operation = Operation(
      document: options.document,
      variables: options.variables,
      operationName: null,
    );

    // execute the operation trough the provided link(s)
    FetchResult fetchResult = await execute(
      link: link,
      operation: operation,
    ).first;

    QueryResult queryResult = _mapFetchResultToQueryResult(fetchResult);

    return queryResult;
  }

  ObservableQuery getQuery(String queryId) {
    return queries[queryId];
  }

  void setQuery(ObservableQuery observableQuery) {
    queries[observableQuery.queryId] = observableQuery;
  }

  int generateQueryId() {
    int requestId = idCounter;

    idCounter++;

    return requestId;
  }

  QueryResult _mapFetchResultToQueryResult(FetchResult fetchResult) {
    List<GraphQLError> errors;

    if (fetchResult.errors != null) {
      errors = List.from(fetchResult.errors.map(
        (rawError) => GraphQLError.fromJSON(rawError),
      ));
    }

    return QueryResult(
      data: fetchResult.data,
      errors: errors,
      loading: false,
    );
  }
}
