import 'dart:async';

import 'package:meta/meta.dart';

import 'package:graphql_flutter/src/core/observable_query.dart';
import 'package:graphql_flutter/src/core/query_result.dart';
import 'package:graphql_flutter/src/core/watch_query_options.dart';

import 'package:graphql_flutter/src/link/link.dart';

abstract class QueryInfo {}

class QueryManager {
  QueryManager({
    @required this.link,
  });

  final Link link;

  int _idCounter = 1;
  Map<String, dynamic> _queries = Map();
  Map<String, dynamic> _queryIdsByName = Map();

  dynamic scheduler;

  Future<QueryResult> query(QueryOptions options) async {
    if (options.document == null) {
      throw new Exception(
          'document option is required. You must specify your GraphQL document in the query option.');
    }

    return await this.watchQuery(options, false).result();
  }

  Future<QueryResult> mutate(QueryOptions options) async {
    return QueryResult();
  }

  ObservableQuery watchQuery(
    WatchQueryOptions options, [
    bool shouldSubscribe = false,
  ]) {
    return new ObservableQuery(
      scheduler: this.scheduler,
      options: options,
      shouldSubscribe: shouldSubscribe,
    );
  }

  String generateQueryId() {
    String queryId = _idCounter.toString();
    _idCounter++;

    return queryId;
  }
}
