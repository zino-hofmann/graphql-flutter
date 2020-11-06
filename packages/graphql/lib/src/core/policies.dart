import 'package:meta/meta.dart';
import "package:collection/collection.dart";

/// [FetchPolicy] determines where the client may return a result from.
///
/// * [cacheFirst] (default): return result from cache. Only fetch from network if cached result is not available.
/// * [cacheAndNetwork]: return result from cache first (if it exists), then return network result once it's available.
/// * [cacheOnly]: return result from cache if available, fail otherwise.
/// * [noCache]: return result from network, fail if network call doesn't succeed, don't save to cache.
/// * [networkOnly]: return result from network, fail if network call doesn't succeed, save to cache.
///
/// The default `fetchPolicy` for each method are:
/// * `watchQuery`: [cacheAndNetwork]
/// * `query`: [cacheFirst]
/// * `mutation`: [networkOnly]
///
/// These can be overriden at client construction time by passing
/// a [DefaultPolicies] instance to `defaultPolicies`.
enum FetchPolicy {
  /// Return result from cache. Only fetch from network if cached result is not available.
  cacheFirst,

  /// Return result from cache first (if it exists), then return network result once it's available.
  cacheAndNetwork,

  /// Return result from cache if available, fail otherwise.
  cacheOnly,

  /// Return result from network, fail if network call doesn't succeed, don't save to cache.
  noCache,

  /// Return result from network, fail if network call doesn't succeed, save to cache.
  networkOnly,
}

// TODO investigate the relationship between optimistic results
// and policy in flutter
bool shouldRespondEagerlyFromCache(FetchPolicy fetchPolicy) =>
    fetchPolicy == FetchPolicy.cacheFirst ||
    fetchPolicy == FetchPolicy.cacheAndNetwork ||
    fetchPolicy == FetchPolicy.cacheOnly;

bool shouldStopAtCache(FetchPolicy fetchPolicy) =>
    fetchPolicy == FetchPolicy.cacheFirst ||
    fetchPolicy == FetchPolicy.cacheOnly;

bool canExecuteOnNetwork(FetchPolicy policy) {
  switch (policy) {
    case FetchPolicy.noCache:
    case FetchPolicy.networkOnly:
      return true;
    case FetchPolicy.cacheFirst:
    case FetchPolicy.cacheAndNetwork:
    case FetchPolicy.cacheOnly:
      return false;
  }
}

/// [ErrorPolicy] determines the level of events for GraphQL Errors in the execution result. The options are:
///
/// While the default for all client methods is [none],
/// [all] is recommended for notifying your users of potential issues.
///
/// * [none] (default): Any GraphQL Errors are treated the same as network errors and any data is ignored from the response.
/// * [ignore]:  Ignore allows you to read any data that is returned alongside GraphQL Errors,
///   but doesn't save the errors or report them to your UI.
/// * [all]: saves both data and errors into the `cache` so your UI can use them.
///   It is recommended for notifying your users of potential issues,
///   while still showing as much data as possible from your server.
///
/// **NOTE**: [ErrorPolicy] only effects **GraphQL Errors**.
/// Client side and network exceptions are added to a [QueryResult] as they occur,
/// and can co-exist alongside data.
enum ErrorPolicy {
  /// Any GraphQL Errors are treated the same as network errors and any data is ignored from the response. (default)
  none,

  /// Ignore allows you to read any data that is returned alongside GraphQL Errors,
  /// but doesn't save the errors or report them to your UI.
  ignore,

  /// saves both data and errors into the `cache` so your UI can use them.
  ///
  ///  It is recommended for notifying your users of potential issues,
  ///  while still showing as much data as possible from your server.
  all,
}

/// Container for supplying a [fetch] and [error] policy.
///
/// If either are `null`, the appropriate policy will be selected from [DefaultPolicies]
@immutable
class Policies {
  /// Specifies the [FetchPolicy] to be used.
  final FetchPolicy fetch;

  /// Specifies the [ErrorPolicy] to be used.
  final ErrorPolicy error;

  Policies({
    this.fetch,
    this.error,
  });

  Policies.safe(
    this.fetch,
    this.error,
  )   : assert(fetch != null, 'fetch policy must be specified'),
        assert(error != null, 'error policy must be specified');

  Policies withOverrides([Policies overrides]) => Policies.safe(
        overrides?.fetch ?? fetch,
        overrides?.error ?? error,
      );

  Policies copyWith({FetchPolicy fetch, ErrorPolicy error}) =>
      Policies(fetch: fetch, error: error);

  operator ==(Object other) =>
      identical(this, other) ||
      (other is Policies && fetch == other.fetch && error == other.error);

  @override
  int get hashCode => const ListEquality<Object>(
        DeepCollectionEquality(),
      ).hash([fetch, error]);

  @override
  String toString() => 'Policies(fetch: $fetch, error: $error)';
}

/// The default [Policies] to set for each client action
@immutable
class DefaultPolicies {
  /// The default [Policies] for watchQuery.
  /// Defaults to
  /// ```
  /// Policies(
  ///   FetchPolicy.cacheAndNetwork,
  ///   ErrorPolicy.none,
  /// )
  /// ```
  final Policies watchQuery;

  /// The default [Policies] for query.
  /// Defaults to
  /// ```
  /// Policies(
  ///   FetchPolicy.cacheFirst,
  ///   ErrorPolicy.none,
  /// )
  /// ```
  final Policies query;

  /// The default [Policies] for mutate.
  /// Defaults to
  /// ```
  /// Policies(
  ///   FetchPolicy.networkOnly,
  ///   ErrorPolicy.none,
  /// )
  /// ```
  final Policies mutate;

  /// The default [Policies] for subscribe.
  /// Defaults to
  /// ```
  /// Policies(
  ///   FetchPolicy.cacheAndNetwork,
  ///   ErrorPolicy.none,
  /// )
  /// ```
  final Policies subscribe;

  DefaultPolicies({
    Policies watchQuery,
    Policies query,
    Policies mutate,
    Policies subscribe,
  })  : watchQuery = _watchQueryDefaults.withOverrides(watchQuery),
        query = _queryDefaults.withOverrides(query),
        mutate = _mutateDefaults.withOverrides(mutate),
        subscribe = _watchQueryDefaults.withOverrides(subscribe);

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

  DefaultPolicies copyWith({
    Policies watchQuery,
    Policies query,
    Policies mutate,
    Policies subscribe,
  }) =>
      DefaultPolicies(
        watchQuery: watchQuery,
        query: query,
        mutate: mutate,
        subscribe: subscribe,
      );

  List<Object> _getChildren() => [
        watchQuery,
        query,
        mutate,
        subscribe,
      ];

  @override
  bool operator ==(Object o) =>
      identical(this, o) ||
      (o is DefaultPolicies &&
          const ListEquality<Object>(
            DeepCollectionEquality(),
          ).equals(
            o._getChildren(),
            _getChildren(),
          ));

  @override
  int get hashCode => const ListEquality<Object>(
        DeepCollectionEquality(),
      ).hash(
        _getChildren(),
      );
}
