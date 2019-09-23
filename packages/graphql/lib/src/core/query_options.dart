import 'package:gql/ast.dart';
import 'package:gql/execution.dart';
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

// TODO investigate the relationship between optimistic results
// and policy in flutter
bool shouldRespondEagerlyFromCache(FetchPolicy fetchPolicy) =>
    fetchPolicy == FetchPolicy.cacheFirst ||
    fetchPolicy == FetchPolicy.cacheAndNetwork ||
    fetchPolicy == FetchPolicy.cacheOnly;

bool shouldStopAtCache(FetchPolicy fetchPolicy) =>
    fetchPolicy == FetchPolicy.cacheFirst ||
    fetchPolicy == FetchPolicy.cacheOnly;

/// [ErrorPolicy] determines the level of events for errors in the execution result. The options are:
/// - none (default): Any GraphQL Errors are treated the same as network errors and any data is ignored from the response.
/// - ignore:  Ignore allows you to read any data that is returned alongside GraphQL Errors,
///  but doesn't save the errors or report them to your UI.
/// - all: Using the all policy is the best way to notify your users of potential issues while still showing as much data as possible from your server.
///  It saves both data and errors into the Apollo Cache so your UI can use them.

enum ErrorPolicy {
  none,
  ignore,
  all,
}

class Policies {
  /// Specifies the [FetchPolicy] to be used.
  FetchPolicy fetch;

  /// Specifies the [ErrorPolicy] to be used.
  ErrorPolicy error;

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
}

/// Base options.
class BaseOptions {
  Request request;

  /// An optimistic result to eagerly add to the operation stream
  Object optimisticResult;

  /// Specifies the [Policies] to be used during execution.
  Policies policies;

  FetchPolicy get fetchPolicy => policies.fetch;

  ErrorPolicy get errorPolicy => policies.error;

  BaseOptions({
    @required this.request,
    this.policies,
    this.optimisticResult,
  });

  // TODO: proper implementation
  String toKey() => request.hashCode.toString();
}

/// Query options.
class QueryOptions extends BaseOptions {
  QueryOptions({
    @required Request request,
    FetchPolicy fetchPolicy = FetchPolicy.cacheFirst,
    ErrorPolicy errorPolicy = ErrorPolicy.none,
    Object optimisticResult,
    this.pollInterval,
    Map<String, dynamic> context,
  }) : super(
          policies: Policies(
            fetch: fetchPolicy,
            error: errorPolicy,
          ),
          request: request,
          optimisticResult: optimisticResult,
        );

  /// The time interval (in milliseconds) on which this query should be
  /// re-fetched from the server.
  int pollInterval;
}

/// Mutation options
class MutationOptions extends BaseOptions {
  MutationOptions({
    @required Request request,
    FetchPolicy fetchPolicy = FetchPolicy.networkOnly,
    ErrorPolicy errorPolicy = ErrorPolicy.none,
    Map<String, dynamic> context,
  }) : super(
          policies: Policies(
            fetch: fetchPolicy,
            error: errorPolicy,
          ),
          request: request,
        );
}

// ObservableQuery options
class WatchQueryOptions extends QueryOptions {
  WatchQueryOptions({
    @required Request request,
    FetchPolicy fetchPolicy = FetchPolicy.cacheAndNetwork,
    ErrorPolicy errorPolicy = ErrorPolicy.none,
    Object optimisticResult,
    int pollInterval,
    this.fetchResults = false,
    this.eagerlyFetchResults,
    Map<String, dynamic> context,
  }) : super(
          request: request,
          fetchPolicy: fetchPolicy,
          errorPolicy: errorPolicy,
          pollInterval: pollInterval,
          optimisticResult: optimisticResult,
        ) {
    this.eagerlyFetchResults ??= fetchResults;
  }

  /// Whether or not to fetch result.
  bool fetchResults;
  bool eagerlyFetchResults;

  /// Checks if the [WatchQueryOptions] in this class are equal to some given options.
  bool areEqualTo(WatchQueryOptions otherOptions) {
    return !_areDifferentOptions(this, otherOptions);
  }

  /// Checks if two options are equal.
  bool _areDifferentOptions(
    WatchQueryOptions a,
    WatchQueryOptions b,
  ) {
    return a.request != b.request &&
        a.policies != b.policies &&
        a.pollInterval != b.pollInterval &&
        a.fetchResults != b.fetchResults;
  }
}

/// merge fetchMore result data with earlier result data
typedef dynamic UpdateQuery(
  dynamic previousResultData,
  dynamic fetchMoreResultData,
);

/// options for fetchmore operations
class FetchMoreOptions {
  final DocumentNode document;
  final Map<String, dynamic> variables;

  /// Strategy for merging the fetchMore result data
  /// with the result data already in the cache
  final UpdateQuery updateQuery;

  const FetchMoreOptions({
    this.document,
    this.variables = const <String, dynamic>{},
    @required this.updateQuery,
  }) : assert(updateQuery != null);
}
