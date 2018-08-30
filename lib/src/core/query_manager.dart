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

typedef SetQueryUpdater = QueryInfo Function(QueryInfo prev);

class QueryInfo {
  List listeners = List();
  String document;
  int lastRequestId;
  ObservableQuery observableQuery;

  QueryInfo({
    this.listeners,
    this.document,
    this.lastRequestId,
    this.observableQuery,
  });

  QueryInfo combine(QueryInfo queryInfo) {
    return QueryInfo(
      listeners: queryInfo.listeners ?? listeners,
      document: queryInfo.document ?? document,
      lastRequestId: queryInfo.lastRequestId ?? lastRequestId,
      observableQuery: queryInfo.observableQuery ?? observableQuery,
    );
  }
}

class QueryManager {
  final Link link;

  QueryScheduler scheduler;

  QueryManager({
    @required this.link,
  }) {
    scheduler = QueryScheduler(
      queryManager: this,
    );
  }

  int idCounter = 1;
  Map<String, QueryInfo> queries = Map();

  ObservableQuery query(QueryOptions options) {
    if (options.document == null) {
      throw new Exception(
          'document option is required. You must specify your GraphQL document in the query options.');
    }

    Operation operation = Operation(
      document: options.document,
      variables: options.variables,
      operationName: null,
    );

    return execute(
      link: link,
      operation: operation,
    ).map(
      _mapFetchResultToQueryResult,
    );
  }

  ObservableQuery mutate(MutationOptions options) {
    if (options.document == null) {
      throw new Exception(
          'document option is required. You must specify your GraphQL document in the mutaion options.');
    }

    Operation operation = Operation(
      document: options.document,
      variables: options.variables,
      operationName: null,
    );

    return execute(
      link: link,
      operation: operation,
    ).map(
      _mapFetchResultToQueryResult,
    );
  }

  QueryInfo getQuery(String queryId) {
    return queries[queryId];
  }

  void setQuery(
    String queryId,
    SetQueryUpdater updater,
  ) {
    if (queries.containsKey(queryId)) {
      QueryInfo prevInfo = getQuery(queryId);
      QueryInfo updaterInfo = updater(prevInfo);
      QueryInfo newInfo = prevInfo.combine(updaterInfo);

      queries.update(queryId, ([_]) => newInfo);
    } else {
      queries.addEntries([MapEntry(queryId, QueryInfo())]);
    }
  }

  FetchResult fetchQuery(
    String queryId,
    WatchQueryOptions options,
  ) {
    // create operation

    // listen to execution

    // add listener to query list
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

  int generateQueryId() {
    int requestId = idCounter;

    idCounter++;

    return requestId;
  }
}
