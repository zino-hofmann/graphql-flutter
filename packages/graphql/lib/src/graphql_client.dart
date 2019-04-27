import 'dart:async';

import 'package:graphql/src/cache/cache.dart';
import 'package:graphql/src/core/observable_query.dart';
import 'package:graphql/src/core/query_manager.dart';
import 'package:graphql/src/core/query_options.dart';
import 'package:graphql/src/core/query_result.dart';
import 'package:graphql/src/link/fetch_result.dart';
import 'package:graphql/src/link/link.dart';
import 'package:graphql/src/link/operation.dart';
import 'package:meta/meta.dart';

/// The link is a [Link] over which GraphQL documents will be resolved into a [FetchResult].
/// The cache is the initial [Cache] to use in the data store.
class GraphQLClient {
  /// Constructs a [GraphQLClient] given a [Link] and a [Cache].
  GraphQLClient({
    @required this.link,
    @required this.cache,
  }) {
    queryManager = QueryManager(
      link: link,
      cache: cache,
    );
  }

  /// The [Link] over which GraphQL documents will be resolved into a [FetchResult].
  final Link link;

  /// The initial [Cache] to use in the data store.
  final Cache cache;

  QueryManager queryManager;

  /// This registers a query in the [QueryManager] and returns an [ObservableQuery]
  /// based on the provided [WatchQueryOptions].
  ObservableQuery watchQuery(WatchQueryOptions options) {
    return queryManager.watchQuery(options);
  }

  /// This resolves a single query according to the [QueryOptions] specified and
  /// returns a [Future] which resolves with the [QueryResult] or throws an [Exception].
  Future<QueryResult> query(QueryOptions options) {
    return queryManager.query(options);
  }

  /// This resolves a single mutation according to the [MutationOptions] specified and
  /// returns a [Future] which resolves with the [QueryResult] or throws an [Exception].
  Future<QueryResult> mutate(MutationOptions options) {
    return queryManager.mutate(options);
  }

  /// This subscribes to a GraphQL subscription according to the options specified and returns a
  /// [Stream] which either emits received data or an error.
  Stream<FetchResult> subscribe(Operation operation) {
    return execute(link: link, operation: operation);
  }
}
