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

/// The default [Policies] to set for each client action
class DefaultPolicies {
  /// The default [Policies] for watchQuery.
  /// Defaults to
  /// ```
  /// Policies(
  ///   FetchPolicy.cacheAndNetwork,
  ///   ErrorPolicy.none,
  /// )
  /// ```
  Policies watchQuery;

  /// The default [Policies] for query.
  /// Defaults to
  /// ```
  /// Policies(
  ///   FetchPolicy.cacheFirst,
  ///   ErrorPolicy.none,
  /// )
  /// ```
  Policies query;

  /// The default [Policies] for mutate.
  /// Defaults to
  /// ```
  /// Policies(
  ///   FetchPolicy.networkOnly,
  ///   ErrorPolicy.none,
  /// )
  /// ```
  Policies mutate;
  DefaultPolicies({
    Policies watchQuery,
    Policies query,
    Policies mutate,
  })  : this.watchQuery = _watchQueryDefaults.withOverrides(watchQuery),
        this.query = _queryDefaults.withOverrides(query),
        this.mutate = _mutateDefaults.withOverrides(mutate);

  static final _watchQueryDefaults = Policies.safe(
    FetchPolicy.cacheAndNetwork,
    ErrorPolicy.none,
  );

  static final _queryDefaults = Policies.safe(
    FetchPolicy.cacheFirst,
    ErrorPolicy.none,
  );
  static final _mutateDefaults = Policies.safe(
    FetchPolicy.networkOnly,
    ErrorPolicy.none,
  );
}

/// The link is a [Link] over which GraphQL documents will be resolved into a [FetchResult].
/// The cache is the initial [Cache] to use in the data store.
class GraphQLClient {
  /// Constructs a [GraphQLClient] given a [Link] and a [Cache].
  GraphQLClient({
    @required this.link,
    @required this.cache,
    this.defaultPolicies,
  }) {
    defaultPolicies ??= DefaultPolicies();
    queryManager = QueryManager(
      link: link,
      cache: cache,
    );
  }

  /// The default [Policies] to set for each client action
  DefaultPolicies defaultPolicies;

  /// The [Link] over which GraphQL documents will be resolved into a [FetchResult].
  final Link link;

  /// The initial [Cache] to use in the data store.
  final Cache cache;

  QueryManager queryManager;

  /// This registers a query in the [QueryManager] and returns an [ObservableQuery]
  /// based on the provided [WatchQueryOptions].
  ObservableQuery watchQuery(WatchQueryOptions options) {
    options.policies =
        defaultPolicies.watchQuery.withOverrides(options.policies);
    return queryManager.watchQuery(options);
  }

  /// This resolves a single query according to the [QueryOptions] specified and
  /// returns a [Future] which resolves with the [QueryResult] or throws an [Exception].
  Future<QueryResult> query(QueryOptions options) {
    options.policies = defaultPolicies.query.withOverrides(options.policies);
    return queryManager.query(options);
  }

  /// This resolves a single mutation according to the [MutationOptions] specified and
  /// returns a [Future] which resolves with the [QueryResult] or throws an [Exception].
  Future<QueryResult> mutate(MutationOptions options) {
    options.policies = defaultPolicies.mutate.withOverrides(options.policies);
    return queryManager.mutate(options);
  }

  /// This subscribes to a GraphQL subscription according to the options specified and returns a
  /// [Stream] which either emits received data or an error.
  Stream<FetchResult> subscribe(Operation operation) {
    return execute(link: link, operation: operation);
  }
}
