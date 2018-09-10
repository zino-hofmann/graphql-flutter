import 'dart:async';

import 'package:meta/meta.dart';

import 'package:graphql_flutter/src/core/query_manager.dart';
import 'package:graphql_flutter/src/core/query_options.dart';
import 'package:graphql_flutter/src/core/query_result.dart';

import 'package:graphql_flutter/src/scheduler/scheduler.dart';

class ObservableQuery {
  final String queryId;
  final QueryScheduler scheduler;
  final QueryManager queryManager;

  WatchQueryOptions options;

  StreamController<QueryResult> controller;

  ObservableQuery({
    @required this.queryManager,
    @required this.options,
  })  : queryId = queryManager.generateQueryId().toString(),
        scheduler = queryManager.scheduler {
    controller = StreamController<QueryResult>.broadcast(
      onListen: onListen,
    );
  }

  Stream<QueryResult> get stream => controller.stream;

  void onListen() {
    if (options.fetchResults) {
      schedule();
    }
  }

  void schedule() {
    if (options.pollInterval != null) {
      final Duration interval = Duration(
        seconds: options.pollInterval,
      );

      queryManager.scheduler.sheduleQuery(
        queryId,
        options,
        interval,
      );
    } else {
      queryManager.scheduler.sheduleQuery(
        queryId,
        options,
      );
    }
  }

  void setVariables(Map<String, dynamic> variables) {
    options.variables = variables;
  }

  void close() {
    controller.close();
  }
}
