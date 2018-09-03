import 'package:meta/meta.dart';

/// [FetchPolicy] determines where the client may return a result from. The options are:
/// - cache_first (default): return result from cache. Only fetch from network if cached result is not available.
/// - cache_and_network: return result from cache first (if it exists), then return network result once it's available.
/// - cache_only: return result from cache if available, fail otherwise.
/// - no_cache: return result from network, fail if network call doesn't succeed, don't save to cache.
/// - network_only: return result from network, fail if network call doesn't succeed, save to cache.
enum FetchPolicy {
  cache_first,
  cache_and_network,
  network_only,
  cache_only,
  no_cache,
}

/// [ErrorPolicy] determines the level of events for errors in the execution result. The options are:
/// - none (default): any errors from the request are treated like runtime errors and the observable is stopped.
/// - ignore: errors from the request do not stop the observable, but also don't call `next`.
/// - all: errors are treated like data and will notify observables.
enum ErrorPolicy {
  none,
  ignore,
  all,
}

/// Base options.
class BaseOptions {
  /// A GraphQL document that consists of a single query to be sent down to the server.
  String document;

  /// A map going from variable name to variable value, where the variables are used
  /// within the GraphQL query.
  Map<String, dynamic> variables;

  /// Specifies the [FetchPolicy] to be used.
  FetchPolicy fetchPolicy;

  /// Specifies the [ErrorPolicy] to be used.
  ErrorPolicy errorPolicy;

  /// Context to be passed to link execution chain.
  dynamic context;
}

/// Query options.
class QueryOptions extends BaseOptions {
  /// A GraphQL document that consists of a single query to be sent down to the server.
  String document;

  /// A map going from variable name to variable value, where the variables are used
  /// within the GraphQL query.
  Map<String, dynamic> variables;

  /// Specifies the [FetchPolicy] to be used for this query.
  FetchPolicy fetchPolicy;

  /// Specifies the [ErrorPolicy] to be used for this query.
  ErrorPolicy errorPolicy;

  /// The time interval (in milliseconds) on which this query should be
  /// refetched from the server.
  int pollInterval;

  /// Context to be passed to link execution chain.
  dynamic context;

  QueryOptions({
    @required this.document,
    this.variables,
    this.fetchPolicy = FetchPolicy.cache_first,
    this.errorPolicy = ErrorPolicy.none,
    this.pollInterval,
    this.context,
  });
}

/// Mutation options
class MutationOptions implements BaseOptions {
  /// A GraphQL document that consists of a single query to be sent down to the server.
  String document;

  /// An object that maps from the name of a variable as used in the mutation
  /// GraphQL document to that variable's value.
  Map<String, dynamic> variables;

  /// Specifies the [FetchPolicy] to be used for this mutation.
  FetchPolicy fetchPolicy;

  /// Specifies the [ErrorPolicy] to be used for this operation.
  ErrorPolicy errorPolicy;

  /// Context to be passed to link execution chain.
  dynamic context;

  MutationOptions({
    @required this.document,
    this.variables,
    this.fetchPolicy = FetchPolicy.network_only,
    this.errorPolicy = ErrorPolicy.none,
    this.context,
  });
}

// ObservableQuery options
class WatchQueryOptions extends BaseOptions {
  /// A GraphQL document that consists of a single query to be sent down to the server.
  String document;

  /// An object that maps from the name of a variable as used in the mutation
  /// GraphQL document to that variable's value.
  Map<String, dynamic> variables;

  /// Specifies the [FetchPolicy] to be used for this query.
  FetchPolicy fetchPolicy;

  /// Specifies the [ErrorPolicy] to be used for this query.
  ErrorPolicy errorPolicy;

  /// The time interval (in milliseconds) on which this query should be
  /// refetched from the server.
  int pollInterval;

  /// Whether or not to fetch result.
  bool fetchResults;

  /// Context to be passed to link execution chain.
  dynamic context;

  WatchQueryOptions({
    @required this.document,
    this.variables,
    this.fetchPolicy = FetchPolicy.cache_and_network,
    this.errorPolicy = ErrorPolicy.none,
    this.pollInterval,
    this.fetchResults,
    this.context,
  });

  bool areEqualTo(WatchQueryOptions otherOptions) {
    return !_areDifferentOptions(this, otherOptions);
  }

  /// Checks if two options are equal.
  bool _areDifferentOptions(
    WatchQueryOptions a,
    WatchQueryOptions b,
  ) {
    if (a.document != b.document) {
      return true;
    }

    if (a.fetchPolicy != b.fetchPolicy) {
      return true;
    }

    if (a.errorPolicy != b.errorPolicy) {
      return true;
    }

    if (a.pollInterval != b.pollInterval) {
      return true;
    }

    if (a.fetchResults != b.fetchResults) {
      return true;
    }

    // compare variables last, because maps take more time
    return _areDifferentVariables(a.variables, b.variables);
  }

  bool _areDifferentVariables(
    Map a,
    Map b,
  ) {
    if (a.length != b.length) {
      return true;
    }

    bool areDifferent = false;

    a.forEach((key, value) {
      if (b[key] != a[key] || (!b.containsKey(key))) {
        areDifferent = true;
      }
    });

    return areDifferent;
  }
}
