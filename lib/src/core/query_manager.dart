import 'dart:async';
import 'package:meta/meta.dart';

import 'package:graphql_flutter/src/core/query_result.dart';
import 'package:graphql_flutter/src/core/graphql_error.dart';
import 'package:graphql_flutter/src/core/query_options.dart';
import 'package:graphql_flutter/src/core/observable_query.dart';

import 'package:graphql_flutter/src/scheduler/scheduler.dart';

import 'package:graphql_flutter/src/link/link.dart';
import 'package:graphql_flutter/src/link/operation.dart';
import 'package:graphql_flutter/src/link/fetch_result.dart';

class QueryManager {
  final Link link;
  final QueryScheduler scheduler = QueryScheduler();

  int idCounter = 1;
  Map<String, ObservableQuery> queries = Map();

  QueryManager({
    @required this.link,
  });

  ObservableQuery query(WatchQueryOptions options) {
    if (options.document == null) {
      throw new Exception(
          'document option is required. You must specify your GraphQL document in the query options.');
    }

    Operation operation = Operation(
      document: options.document,
      variables: options.variables,
      operationName: null,
    );

    ObservableQuery observableQuery = ObservableQuery(
      queryManager: this,
      operation: operation,
    );

    queries[observableQuery.queryId] = observableQuery;

    scheduler.sheduleQuery(observableQuery);

    return observableQuery;
  }

  ObservableQuery mutate(MutationOptions options) {
    if (options.document == null) {
      throw new Exception(
          'document option is required. You must specify your GraphQL document in the mutaion options.');
    }
  }

  ObservableQuery getQuery(String queryId) {
    if (queries.containsKey(queryId)) {
      return queries[queryId];
    }

    return null;
  }

  void setQuery(ObservableQuery observableQuery) {
    queries[observableQuery.queryId] = observableQuery;
  }

  int generateQueryId() {
    int requestId = idCounter;

    idCounter++;

    return requestId;
  }
}
