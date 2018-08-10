import 'dart:async';

import 'package:meta/meta.dart';

import 'package:graphql_flutter/src/core/query_manager.dart';
import 'package:graphql_flutter/src/core/query_result.dart';
import 'package:graphql_flutter/src/core/watch_query_options.dart';

import 'package:graphql_flutter/src/link/link.dart';
import 'package:graphql_flutter/src/cache/cache.dart';

/// The link is a [Link] over which GraphQL documents will be resolved into a response.
/// The cache is the initial [Cache] to use in the data store.
class GraphqlClient {
  GraphqlClient({
    @required this.link,
    @required this.cache,
  });

  final Link link;
  final Cache cache;

  QueryManager queryManager;

  /// This initializes the query manager that tracks queries and the cache
  QueryManager initQueryManager() {
    if (queryManager != null) {
      this.queryManager = QueryManager(
        link: link,
      );
    }

    return queryManager;
  }

  /// This resolves a single query according to the options specified and
  /// returns a [Future] which is either resolved with the resulting data
  /// or rejected with an error.
  Future<QueryResult> query(QueryOptions options) {
    return initQueryManager().query(options);
  }

  /// This resolves a single mutation according to the options specified and returns a
  /// [Future] which is either resolved with the resulting data or rejected with an
  /// error.
  Future<QueryResult> mutate(QueryOptions options) {
    return initQueryManager().mutate(options);
  }

  /// This subscribes to a graphql subscription according to the options specified and returns an
  /// [Stream] which either emits received data or an error.
  subscribe(options) {
    // TODO: merge the subscription client with the new client
  }
}
