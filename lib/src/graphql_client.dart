import 'dart:async';

import 'package:meta/meta.dart';

import 'package:graphql_flutter/src/core/query_manager.dart';
import 'package:graphql_flutter/src/core/observable_query.dart';
import 'package:graphql_flutter/src/core/query_options.dart';

import 'package:graphql_flutter/src/link/link.dart';
import 'package:graphql_flutter/src/cache/cache.dart';

/// The link is a [Link] over which GraphQL documents will be resolved into a response.
/// The cache is the initial [Cache] to use in the data store.
class GraphQLClient {
  final Link link;
  final Cache cache;

  QueryManager queryManager;
  Cache proxy;

  GraphQLClient({
    @required this.link,
    @required this.cache,
  });

  /// This resolves a single query according to the options specified and
  /// returns a [ObservableQuery] which emits the resulting data or an error.
  ObservableQuery query(QueryOptions options) {
    return initQueryManager().query(options);
  }

  /// This resolves a single mutation according to the options specified and returns a
  /// [ObservableQuery] which emits the resulting data or an error.
  ObservableQuery mutate(MutationOptions options) {
    return initQueryManager().mutate(options);
  }

  /// This subscribes to a graphql subscription according to the options specified and returns an
  /// [Stream] which either emits received data or an error.
  Stream subscribe(options) {
    // TODO: merge the subscription client with the new client
  }

  /// This initializes the query manager that tracks queries and the cache
  QueryManager initQueryManager() {
    if (queryManager == null) {
      queryManager = QueryManager(
        link: link,
      );
    }

    return queryManager;
  }

  /// Initializes a data proxy for this client instance if one does not already
  /// exist and returns either a previously initialized proxy instance or the
  /// newly initialized instance.
  Cache _initProxy() {
    if (proxy == null) {
      initQueryManager();
      proxy = cache;
    }

    return proxy;
  }
}
