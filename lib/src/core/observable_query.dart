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
  bool isCurrentlyPolling = false;

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
      fetchResults();
    }
  }

  void fetchResults() {
    queryManager.fetchQuery(queryId, options);

    if (options.pollInterval != null) {
      startPolling(options.pollInterval);
    }
  }

  void startPolling(int pollInterval) {
    if (options.fetchPolicy == FetchPolicy.cacheFirst ||
        options.fetchPolicy == FetchPolicy.cacheOnly) {
      throw Exception(
        'Queries that specify the cacheFirst and cacheOnly fetch policies cannot also be polling queries.',
      );
    }

    if (isCurrentlyPolling) {
      scheduler.stopPollingQuery(queryId);
      isCurrentlyPolling = false;
    }

    options.pollInterval = pollInterval;
    isCurrentlyPolling = true;
    scheduler.startPollingQuery(options, queryId);
  }

  void stopPolling() {
    if (isCurrentlyPolling) {
      scheduler.stopPollingQuery(queryId);
      options.pollInterval = null;
      isCurrentlyPolling = false;
    }
  }

  void setVariables(Map<String, dynamic> variables) {
    options.variables = variables;
  }

  Future<void> close() async {
    stopPolling();
    await controller.close();
  }
}
