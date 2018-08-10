import 'dart:async';

import 'package:graphql_flutter/src/core/query_scheduler.dart';
import 'package:graphql_flutter/src/core/query_manager.dart';
import 'package:graphql_flutter/src/core/query_result.dart';
import 'package:graphql_flutter/src/core/watch_query_options.dart';

class ObservableQuery {
  ObservableQuery({
    QueryScheduler scheduler,
    WatchQueryOptions options,
    bool shouldSubscribe,
  }) {
    // active state
    this._isCurrentlyPolling = false;
    this._isTornDown = false;

    // query information
    this.options = options;
    this.variables = options.variables ?? {};
    this.queryId = scheduler.queryManager.generateQueryId();
    this._shouldSubscribe = shouldSubscribe;

    // related classes
    this._scheduler = scheduler;
    this._queryManager = scheduler.queryManager;

    // interal data stores
    this._observers = [];
    this._subscriptionHandles = [];
  }

  bool _isCurrentlyPolling;
  bool _shouldSubscribe;
  bool _isTornDown;
  QueryScheduler _scheduler;
  QueryManager _queryManager;
  dynamic _observers;
  dynamic _subscriptionHandles;

  QueryResult _lastResult;
  Exception _lastError;

  WatchQueryOptions options;
  String queryId;
  Map<String, dynamic> variables;

  Future result() async {}
}
