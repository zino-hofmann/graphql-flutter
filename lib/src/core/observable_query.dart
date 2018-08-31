import 'dart:async';

import 'package:meta/meta.dart';

import 'package:graphql_flutter/src/core/graphql_error.dart';
import 'package:graphql_flutter/src/core/query_manager.dart';
import 'package:graphql_flutter/src/core/query_result.dart';

import 'package:graphql_flutter/src/scheduler/scheduler.dart';

import 'package:graphql_flutter/src/link/link.dart';
import 'package:graphql_flutter/src/link/operation.dart';
import 'package:graphql_flutter/src/link/fetch_result.dart';

class ObservableQuery {
  String queryId;

  Operation operation;
  int pollInterval;
  QueryScheduler scheduler;
  QueryManager queryManager;

  StreamController<QueryResult> _controller;
  List<StreamSubscription<QueryResult>> subscriptions = List();

  QueryResult lastResult;
  GraphQLError lastError;

  ObservableQuery({
    @required this.queryManager,
    @required this.operation,
    this.pollInterval,
  }) {
    _controller = StreamController.broadcast();
    queryId = queryManager.generateQueryId().toString();

    scheduler = queryManager.scheduler;
  }

  StreamSink<QueryResult> get stream => _controller;

  Future<QueryResult> fetchQuery() async {
    // execute the operation trough the provided link(s)
    FetchResult fetchResult = await execute(
      link: queryManager.link,
      operation: operation,
    ).last;

    QueryResult queryResult = _mapFetchResultToQueryResult(fetchResult);

    // emit the event to the stream controller
    _controller.add(queryResult);

    return queryResult;
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
