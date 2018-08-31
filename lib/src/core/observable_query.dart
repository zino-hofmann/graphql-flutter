import 'dart:async';

import 'package:meta/meta.dart';

import 'package:graphql_flutter/src/core/graphql_error.dart';
import 'package:graphql_flutter/src/core/query_manager.dart';
import 'package:graphql_flutter/src/core/query_options.dart';
import 'package:graphql_flutter/src/core/query_result.dart';

import 'package:graphql_flutter/src/scheduler/scheduler.dart';

import 'package:graphql_flutter/src/link/link.dart';
import 'package:graphql_flutter/src/link/operation.dart';
import 'package:graphql_flutter/src/link/fetch_result.dart';

class ObservableQuery {
  String queryId;

  ObservalbeQueryOptions options;
  QueryScheduler scheduler;
  QueryManager queryManager;

  StreamController<QueryResult> _controller;

  ObservableQuery({
    @required this.queryManager,
    @required this.options,
  }) {
    queryId = queryManager.generateQueryId().toString();
    scheduler = queryManager.scheduler;

    _controller = StreamController.broadcast();
  }

  Stream<QueryResult> get stream => _controller.stream;

  Future<QueryResult> fetchQuery() async {
    // create a new operation to fetch
    Operation operation = Operation(
      document: options.document,
      variables: options.variables,
      operationName: null,
    );

    // execute the operation trough the provided link(s)
    FetchResult fetchResult = await execute(
      link: queryManager.link,
      operation: operation,
    ).last;

    QueryResult queryResult = _mapFetchResultToQueryResult(fetchResult);

    // emit the event to the stream
    _controller.add(queryResult);

    return queryResult;
  }

  void schedule() {
    queryManager.scheduler.sheduleQuery(this);
  }

  void scheduleOnInterval(Duration interval) {
    queryManager.scheduler.sheduleQuery(
      this,
      interval,
    );
  }

  void setVariables(Map<String, dynamic> variables) {
    options.variables = variables;
  }

  void close() {
    _controller.close();
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
