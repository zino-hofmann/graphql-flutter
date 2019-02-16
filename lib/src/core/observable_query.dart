import 'dart:async';

import 'package:meta/meta.dart';

import 'package:graphql_flutter/src/core/query_manager.dart';
import 'package:graphql_flutter/src/core/query_options.dart';
import 'package:graphql_flutter/src/core/query_result.dart';

import 'package:graphql_flutter/src/scheduler/scheduler.dart';

typedef void OnData(QueryResult result);

enum QueryLifecycle {
  UNEXECUTED,
  PENDING,
  POLLING,
  POLLING_STOPPED,
  SIDE_EFFECTS_PENDING,
  SIDE_EFFECTS_BLOCKING,

  // right now only Mutations ever become completed
  COMPLETED,
}

class ObservableQuery {
  ObservableQuery({
    @required this.queryManager,
    @required this.options,
  })  : queryId = queryManager.generateQueryId().toString(),
        scheduler = queryManager.scheduler {
    controller = StreamController<QueryResult>.broadcast(
      onListen: onListen,
    );
  }

  final String queryId;
  final QueryScheduler scheduler;
  final QueryManager queryManager;

  final Set<StreamSubscription<QueryResult>> _onDataSubscriptions =
      Set<StreamSubscription<QueryResult>>();

  QueryLifecycle lifecycle = QueryLifecycle.UNEXECUTED;

  WatchQueryOptions options;

  StreamController<QueryResult> controller;

  Stream<QueryResult> get stream => controller.stream;
  bool get isCurrentlyPolling => lifecycle == QueryLifecycle.POLLING;

  void onListen() {
    if (options.fetchResults) {
      fetchResults();
    }
  }

  void fetchResults() {
    queryManager.fetchQuery(queryId, options);

    // if onData callbacks have been registered,
    // they should be waited on by default
    lifecycle = _onDataSubscriptions.isNotEmpty
        ? QueryLifecycle.SIDE_EFFECTS_PENDING
        : QueryLifecycle.PENDING;

    if (options.pollInterval != null) {
      startPolling(options.pollInterval);
    }
  }

  void sendLoading() {
    controller.add(
      QueryResult(
        loading: true,
      ),
    );
  }

  // most mutation behavior happens here
  void onData(Iterable<OnData> callbacks) {
    if (callbacks != null && callbacks.isNotEmpty) {
      StreamSubscription<QueryResult> subscription;

      subscription = stream.listen((QueryResult result) {
        void handle(OnData callback) {
          callback(result);
        }

        if (!result.loading) {
          callbacks.forEach(handle);
          subscription.cancel();
          _onDataSubscriptions.remove(subscription);

          if (_onDataSubscriptions.isEmpty) {
            if (lifecycle == QueryLifecycle.SIDE_EFFECTS_BLOCKING) {
              lifecycle = QueryLifecycle.COMPLETED;
              close();
            }

            lifecycle = QueryLifecycle.COMPLETED;
          }
        }
      });

      _onDataSubscriptions.add(subscription);
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
    }

    options.pollInterval = pollInterval;
    lifecycle = QueryLifecycle.POLLING;
    scheduler.startPollingQuery(options, queryId);
  }

  void stopPolling() {
    if (isCurrentlyPolling) {
      scheduler.stopPollingQuery(queryId);
      options.pollInterval = null;
      lifecycle = QueryLifecycle.POLLING_STOPPED;
    }
  }

  void setVariables(Map<String, dynamic> variables) {
    options.variables = variables;
  }

  Future<void> close({bool force = false, bool fromManager = false}) async {
    if (lifecycle == QueryLifecycle.SIDE_EFFECTS_PENDING && !force) {
      lifecycle = QueryLifecycle.SIDE_EFFECTS_BLOCKING;
      return null;
    }

    if (!fromManager) {
      queryManager.closeQuery(this, fromQuery: true);
    }

    for (StreamSubscription<QueryResult> subscription in _onDataSubscriptions) {
      subscription.cancel();
    }

    stopPolling();
    await controller.close();
  }
}
