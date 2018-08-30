import 'dart:async';

import 'package:graphql_flutter/src/core/graphql_error.dart';
import 'package:graphql_flutter/src/core/query_manager.dart';
import 'package:graphql_flutter/src/core/query_result.dart';
import 'package:graphql_flutter/src/core/query_options.dart';
import 'package:graphql_flutter/src/scheduler/scheduler.dart';

class ObservableQuery {
  StreamController controller;

  WatchQueryOptions options;
  String queryId;

  /// The current value of the variables for this query. Can change.
  Map<String, dynamic> variables;
  bool isCurrentlyPolling;
  bool shouldSubscribe;
  bool isTornDown;
  QueryScheduler scheduler;
  QueryManager queryManager;

  QueryResult lastResult;
  GraphQLError lastError;

  ObservableQuery({
    this.options,
    this.shouldSubscribe = false,
  }) {
    // observable
    controller = StreamController.broadcast();

    // active state
    isCurrentlyPolling = false;
    isTornDown = false;

    // query information
    variables = options.variables ?? {};
    queryId = scheduler.queryManager.generateQueryId().toString();

    // related classes
    queryManager = scheduler.queryManager;
  }

  result() {
    // listen to this stream

    // return the first result
  }

  currentResult() {
    // check if torn down

    // call queryManager.getCurrentQueryResult(this);

    // return the result
  }

  void close() {
    controller.close();
  }
}
