import 'package:meta/meta.dart';
import 'dart:async';

import 'package:graphql/src/core/core.dart';
import 'package:graphql/src/cache/cache.dart';

import 'package:graphql/src/core/fetch_more.dart';

/// The link is a [Link] over which GraphQL documents will be resolved into a [Response].
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

  /// The [Link] over which GraphQL documents will be resolved into a [Response].
  final Link link;

  /// The initial [Cache] to use in the data store.
  final GraphQLCache cache;

  QueryManager queryManager;

  /// This registers a query in the [QueryManager] and returns an [ObservableQuery]
  /// based on the provided [WatchQueryOptions].
  ///
  /// {@tool snippet}
  ///
  /// Basic usage
  /// ```dart
  ///
  /// result = client.watchQuery(WatchQueryOptions(
  ///  options: QueryOptions(
  ///    document: gql(r'''
  ///      query HeroForEpisode($ep: Episode!) {
  ///        hero(episode: $ep) {
  ///          __typename
  ///          name
  ///          ... on Droid {
  ///            primaryFunction
  ///          }
  ///          ... on Human {
  ///            height
  ///            homePlanet
  ///          }
  ///        }
  ///      }
  ///    '''),
  ///    variables: <String, String>{
  ///      'ep': episodeToJson(episode),
  ///    },
  ///  ),
  /// ));
  ///
  /// result.stream.listen((QueryResult result) {
  ///   if (!result.loading && result.data != null) {
  ///     add(
  ///       GraphqlLoadedEvent<T>(
  ///         data: parseData(result.data as Map<String, dynamic>),
  ///         result: result,
  ///       ),
  ///     );
  ///   }
  ///   if (result.hasException) {
  ///     add(GraphqlErrorEvent(error: result.exception, result: result));
  ///   }
  /// });
  /// ```
  /// {@end-tool}
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
  Stream<QueryResult> subscribe(SubscriptionOptions options) {
    options.policies = defaultPolicies.subscribe.withOverrides(
      options.policies,
    );
    return queryManager.subscribe(options);
  }

  /// Fetch more results and then merge them with the given [previousResult]
  /// according to [FetchMoreOptions.updateQuery].
  Future<QueryResult> fetchMore(
    FetchMoreOptions fetchMoreOptions, {
    @required QueryOptions originalOptions,
    @required QueryResult previousResult,
  }) =>
      fetchMoreImplementation(
        fetchMoreOptions,
        originalOptions: originalOptions,
        previousResult: previousResult,
        queryManager: queryManager,
      );
}
