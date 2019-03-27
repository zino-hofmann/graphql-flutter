import 'package:meta/meta.dart';

/// [FetchPolicy] determines where the client may return a result from. The options are:
/// - cacheFirst (default): return result from cache. Only fetch from network if cached result is not available.
/// - cacheAndNetwork: return result from cache first (if it exists), then return network result once it's available.
/// - cacheOnly: return result from cache if available, fail otherwise.
/// - noCache: return result from network, fail if network call doesn't succeed, don't save to cache.
/// - networkOnly: return result from network, fail if network call doesn't succeed, save to cache.
enum FetchPolicy {
  cacheFirst,
  cacheAndNetwork,
  cacheOnly,
  noCache,
  networkOnly,
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
  BaseOptions({
    @required this.document,
    this.variables,
    this.fetchPolicy,
    this.errorPolicy,
    this.context,
  });

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
  Map<String, dynamic> context;
}

/// Query options.
class QueryOptions extends BaseOptions {
  QueryOptions({
    @required String document,
    Map<String, dynamic> variables,
    FetchPolicy fetchPolicy = FetchPolicy.cacheFirst,
    ErrorPolicy errorPolicy = ErrorPolicy.none,
    this.pollInterval,
    Map<String, dynamic> context,
  }) : super(
          document: document,
          variables: variables,
          fetchPolicy: fetchPolicy,
          errorPolicy: errorPolicy,
          context: context,
        );

  /// The time interval (in milliseconds) on which this query should be
  /// refetched from the server.
  int pollInterval;
}

/// Mutation options
class MutationOptions extends BaseOptions {
  MutationOptions({
    @required String document,
    Map<String, dynamic> variables,
    FetchPolicy fetchPolicy = FetchPolicy.networkOnly,
    ErrorPolicy errorPolicy = ErrorPolicy.none,
    Map<String, dynamic> context,
  }) : super(
          document: document,
          variables: variables,
          fetchPolicy: fetchPolicy,
          errorPolicy: errorPolicy,
          context: context,
        );
}

// ObservableQuery options
class WatchQueryOptions extends QueryOptions {
  WatchQueryOptions({
    @required String document,
    Map<String, dynamic> variables,
    FetchPolicy fetchPolicy = FetchPolicy.cacheAndNetwork,
    ErrorPolicy errorPolicy = ErrorPolicy.none,
    int pollInterval,
    this.fetchResults,
    Map<String, dynamic> context,
  }) : super(
          document: document,
          variables: variables,
          fetchPolicy: fetchPolicy,
          errorPolicy: errorPolicy,
          pollInterval: pollInterval,
          context: context,
        );

  /// Whether or not to fetch result.
  bool fetchResults;

  /// Checks if the [WatchQueryOptions] in this class are equal to some given options.
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
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    if (a == null && b == null) {
      return false;
    }

    if (a == null || b == null) {
      return true;
    }

    if (a.length != b.length) {
      return true;
    }

    bool areDifferent = false;

    a.forEach((String key, dynamic value) {
      if ((!b.containsKey(key)) || b[key] != value) {
        areDifferent = true;
      }
    });

    return areDifferent;
  }
}
