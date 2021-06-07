import 'package:meta/meta.dart';
import 'dart:async';

import 'package:graphql/src/core/core.dart';
import 'package:graphql/src/cache/cache.dart';

import 'package:graphql/src/core/fetch_more.dart';

/// Universal GraphQL Client with configurable caching and [link][] system.
/// modelled after the [`apollo-client`][ac].
///
/// The link is a [Link] over which GraphQL documents will be resolved into a [Response].
/// The cache is the [GraphQLCache] to use for caching results and optimistic updates.
///
/// The client automatically rebroadcasts watched queries when their underlying data
/// changes in the cache. To skip the data comparison check, `alwaysRebroadcast: true` can be passed.
/// **NOTE**: This flag was added ot accomodate the old default behavior.
/// It is marked `@experimental` because it may be deprecated in the future.
///
/// [ac]: https://www.apollographql.com/docs/react/v3.0-beta/api/core/ApolloClient/
/// [link]: https://github.com/gql-dart/gql/tree/master/links/gql_link
class GraphQLClient implements GraphQLDataProxy {
  /// Constructs a [GraphQLClient] given a [Link] and a [Cache].
  GraphQLClient({
    required this.link,
    required this.cache,
    DefaultPolicies? defaultPolicies,
    bool alwaysRebroadcast = false,
  })  : defaultPolicies = defaultPolicies ?? DefaultPolicies(),
        queryManager = QueryManager(
          link: link,
          cache: cache,
          alwaysRebroadcast: alwaysRebroadcast,
        );

  /// The default [Policies] to set for each client action
  late final DefaultPolicies defaultPolicies;

  /// The [Link] over which GraphQL documents will be resolved into a [Response].
  final Link link;

  /// The initial [Cache] to use in the data store.
  final GraphQLCache cache;

  late final QueryManager queryManager;

  /// This registers a query in the [QueryManager] and returns an [ObservableQuery]
  /// based on the provided [WatchQueryOptions].
  ///
  /// {@tool snippet}
  /// Basic usage
  ///
  /// ```dart
  /// final observableQuery = client.watchQuery(
  ///   WatchQueryOptions(
  ///     document: gql(
  ///       r'''
  ///       query HeroForEpisode($ep: Episode!) {
  ///         hero(episode: $ep) {
  ///           name
  ///         }
  ///       }
  ///       ''',
  ///     ),
  ///     variables: {'ep': 'NEWHOPE'},
  ///   ),
  /// );
  ///
  /// /// Listen to the stream of results. This will include:
  /// /// * `options.optimisitcResult` if passed
  /// /// * The result from the server (if `options.fetchPolicy` includes networking)
  /// /// * rebroadcast results from edits to the cache
  /// observableQuery.stream.listen((QueryResult result) {
  ///   if (!result.isLoading && result.data != null) {
  ///     if (result.hasException) {
  ///       print(result.exception);
  ///       return;
  ///     }
  ///     if (result.isLoading) {
  ///       print('loading');
  ///       return;
  ///     }
  ///     doSomethingWithMyQueryResult(myCustomParser(result.data));
  ///   }
  /// });
  /// // ... cleanup:
  /// observableQuery.close();
  /// ```
  /// {@end-tool}
  ObservableQuery watchQuery(WatchQueryOptions options) {
    options.policies =
        defaultPolicies.watchQuery.withOverrides(options.policies);
    return queryManager.watchQuery(options);
  }

  /// [watchMutation] is the same as [watchQuery], but with a different [defaultPolicies] that are more appropriate for mutations.
  ///
  /// This is a stop-gap solution to the problems created by the reliance of `graphql_flutter` on [ObservableQuery] for mutations.
  ///
  /// For more details, see https://github.com/zino-app/graphql-flutter/issues/774
  ObservableQuery watchMutation(WatchQueryOptions options) {
    options.policies =
        defaultPolicies.watchMutation.withOverrides(options.policies);
    return queryManager.watchQuery(options);
  }

  /// This resolves a single query according to the [QueryOptions] specified and
  /// returns a [Future] which resolves with the [QueryResult] or throws an [Exception].
  ///
  /// {@tool snippet}
  /// Basic usage
  ///
  /// ```dart
  /// final QueryResult result = await client.query(
  ///   QueryOptions(
  ///     document: gql(
  ///       r'''
  ///       query ReadRepositories($nRepositories: Int!) {
  ///         viewer {
  ///           repositories(last: $nRepositories) {
  ///             nodes {
  ///               __typename
  ///               id
  ///               name
  ///               viewerHasStarred
  ///             }
  ///           }
  ///         }
  ///       }
  ///     ''',
  ///     ),
  ///     variables: {
  ///       'nRepositories': 50,
  ///     },
  ///   ),
  /// );
  ///
  /// if (result.hasException) {
  ///   print(result.exception.toString());
  /// }
  ///
  /// final List<dynamic> repositories =
  ///     result.data['viewer']['repositories']['nodes'] as List<dynamic>;
  /// ```
  /// {@end-tool}

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
  ///
  /// {@tool snippet}
  /// Basic usage
  ///
  /// ```dart
  /// subscription = client.subscribe(
  ///   SubscriptionOptions(
  ///     document: gql(
  ///       r'''
  ///         subscription reviewAdded {
  ///           reviewAdded {
  ///             stars, commentary, episode
  ///           }
  ///         }
  ///       ''',
  ///     ),
  ///   ),
  /// );
  ///
  /// subscription.listen((result) {
  ///   if (result.hasException) {
  ///     print(result.exception.toString());
  ///     return;
  ///   }
  ///
  ///   if (result.isLoading) {
  ///     print('awaiting results');
  ///     return;
  ///   }
  ///
  ///   print('New Review: ${result.data}');
  /// });
  /// ```
  /// {@end-tool}
  Stream<QueryResult> subscribe(SubscriptionOptions options) {
    options.policies = defaultPolicies.subscribe.withOverrides(
      options.policies,
    );
    return queryManager.subscribe(options);
  }

  /// Fetch more results and then merge them with the given [previousResult]
  /// according to [FetchMoreOptions.updateQuery].
  ///
  /// **NOTE**: with the addition of strict data structure checking in v4,
  /// it is easy to make mistakes in writing [updateQuery].
  ///
  /// To mitigate this, [FetchMoreOptions.partial] has been provided.
  @experimental
  Future<QueryResult> fetchMore(
    FetchMoreOptions fetchMoreOptions, {
    required QueryOptions originalOptions,
    required QueryResult previousResult,
  }) =>
      fetchMoreImplementation(
        fetchMoreOptions,
        originalOptions: originalOptions,
        previousResult: previousResult,
        queryManager: queryManager,
      );

  /// pass through to [cache.readQuery]
  readQuery(request, {optimistic = true}) =>
      cache.readQuery(request, optimistic: optimistic);

  /// pass through to [cache.readFragment]
  readFragment(
    fragmentRequest, {
    optimistic = true,
  }) =>
      cache.readFragment(
        fragmentRequest,
        optimistic: optimistic,
      );

  /// pass through to [cache.writeQuery] and then rebroadcast any changes.
  void writeQuery(request, {required data, broadcast = true}) {
    cache.writeQuery(request, data: data, broadcast: broadcast);
    queryManager.maybeRebroadcastQueries();
  }

  /// pass through to [cache.writeFragment] and then rebroadcast any changes.
  void writeFragment(
    fragmentRequest, {
    broadcast = true,
    required data,
  }) {
    cache.writeFragment(
      fragmentRequest,
      broadcast: broadcast,
      data: data,
    );
    queryManager.maybeRebroadcastQueries();
  }

  /// Resets the contents of the store with [cache.store.reset()]
  /// and then refetches of all queries unless [refetchQueries] is disabled
  @experimental
  Future<List<QueryResult?>>? resetStore({bool refetchQueries = true}) {
    cache.store.reset();
    if (refetchQueries) {
      return queryManager.refetchSafeQueries();
    }
    return null;
  }
}
