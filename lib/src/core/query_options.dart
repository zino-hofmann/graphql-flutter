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

/// Query options.
class QueryOptions {
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

  /// Whether or not to fetch result.
  bool fetchResults;

  /// Whether or not updates to the network status should trigger next on the observer of this query.
  bool notifyOnNetworkStatusChange;

  /// Context to be passed to link execution chain.
  dynamic context;

  QueryOptions({
    @required this.document,
    this.variables,
    this.fetchPolicy,
    this.errorPolicy,
    this.pollInterval,
    this.fetchResults,
    this.notifyOnNetworkStatusChange,
    this.context,
  });
}

/// Mutation options
class MutationOptions {
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
    this.fetchPolicy,
    this.errorPolicy,
    this.context,
  });
}

// ObservableQuery options
class ObservalbeQueryOptions {
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

  /// Context to be passed to link execution chain.
  dynamic context;

  ObservalbeQueryOptions({
    @required this.document,
    this.variables,
    this.fetchPolicy,
    this.errorPolicy,
    this.pollInterval,
    this.context,
  });
}
