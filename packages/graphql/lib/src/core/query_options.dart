import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:graphql/client.dart';
import 'package:graphql/internal.dart';
import 'package:graphql/src/core/raw_operation_data.dart';
import 'package:graphql/src/utilities/helpers.dart';
import 'package:meta/meta.dart';

/// Parse GraphQL query strings into the standard GraphQL AST.
DocumentNode gql(String query) => parseString(query);

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
class BaseOptions extends RawOperationData {
  BaseOptions({
    @Deprecated('The "document" option has been deprecated, use "documentNode" instead')
        String document,
    DocumentNode documentNode,
    Map<String, dynamic> variables,
    this.policies,
    this.context,
    this.optimisticResult,
  }) : super(
          // ignore: deprecated_member_use_from_same_package
          document: document,
          documentNode: documentNode,
          variables: variables,
        );

  /// An optimistic result to eagerly add to the operation stream
  Object optimisticResult;

  /// Specifies the [Policies] to be used during execution.
  Policies policies;

  FetchPolicy get fetchPolicy => policies.fetch;

  ErrorPolicy get errorPolicy => policies.error;

  /// Context to be passed to link execution chain.
  Map<String, dynamic> context;
}

/// Query options.
class QueryOptions extends BaseOptions {
  QueryOptions({
    @Deprecated('The "document" option has been deprecated, use "documentNode" instead')
        String document,
    DocumentNode documentNode,
    Map<String, dynamic> variables,
    FetchPolicy fetchPolicy,
    ErrorPolicy errorPolicy,
    Object optimisticResult,
    this.pollInterval,
    Map<String, dynamic> context,
  }) : super(
          policies: Policies(fetch: fetchPolicy, error: errorPolicy),
          // ignore: deprecated_member_use_from_same_package
          document: document,
          documentNode: documentNode,
          variables: variables,
          context: context,
          optimisticResult: optimisticResult,
        );

  /// The time interval (in milliseconds) on which this query should be
  /// re-fetched from the server.
  int pollInterval;
}

typedef OnMutationCompleted = void Function(dynamic data);
typedef OnMutationUpdate = void Function(Cache cache, QueryResult result);
typedef OnError = void Function(OperationException error);

/// Mutation options
class MutationOptions extends BaseOptions {
  MutationOptions({
    @Deprecated('The "document" option has been deprecated, use "documentNode" instead')
        String document,
    DocumentNode documentNode,
    Map<String, dynamic> variables,
    FetchPolicy fetchPolicy,
    ErrorPolicy errorPolicy,
    Map<String, dynamic> context,
    this.onCompleted,
    this.update,
    this.onError,
  }) : super(
          policies: Policies(fetch: fetchPolicy, error: errorPolicy),
          // ignore: deprecated_member_use_from_same_package
          document: document,
          documentNode: documentNode,
          variables: variables,
          context: context,
        );

  OnMutationCompleted onCompleted;
  OnMutationUpdate update;
  OnError onError;
}

class MutationCallbacks {
  final MutationOptions options;
  final Cache cache;
  final String queryId;

  MutationCallbacks({
    this.options,
    this.cache,
    this.queryId,
  })  : assert(cache != null),
        assert(options != null),
        assert(queryId != null);

  // callbacks will be called against each result in the stream,
  // which should then rebroadcast queries with the appropriate optimism
  Iterable<OnData> get callbacks =>
      <OnData>[onCompleted, update, onError].where(notNull);

  // Todo: probably move this to its own class
  OnData get onCompleted {
    if (options.onCompleted != null) {
      return (QueryResult result) {
        if (!result.loading && !result.optimistic) {
          return options.onCompleted(result.data);
        }
      };
    }
    return null;
  }

  OnData get onError {
    if (options.onError != null) {
      return (QueryResult result) {
        if (!result.loading &&
            result.hasException &&
            options.errorPolicy != ErrorPolicy.ignore) {
          return options.onError(result.exception);
        }
      };
    }

    return null;
  }

  /// The optimistic cache layer id `update` will write to
  /// is a "child patch" of the default optimistic patch
  /// created by the query manager
  String get _patchId => '${queryId}.update';

  /// apply the user's patch
  void _optimisticUpdate(QueryResult result) {
    final String patchId = _patchId;
    // this is also done in query_manager, but better safe than sorry
    assert(cache is OptimisticCache,
        "can't optimisticly update non-optimistic cache");
    (cache as OptimisticCache).addOptimisiticPatch(patchId, (Cache cache) {
      options.update(cache, result);
      return cache;
    });
  }

  // optimistic patches will be cleaned up by the query_manager
  // cleanup is handled by heirarchical optimism -
  // as in, because our patch id is prefixed with '${observableQuery.queryId}.',
  // it will be discarded along with the observableQuery.queryId patch
  // TODO this results in an implicit coupling with the patch id system
  OnData get update {
    if (options.update != null) {
      // dereference all variables that might be needed if the widget is disposed
      final OnMutationUpdate widgetUpdate = options.update;
      final OnData optimisticUpdate = _optimisticUpdate;

      // wrap update logic to handle optimism
      void updateOnData(QueryResult result) {
        if (result.optimistic) {
          return optimisticUpdate(result);
        } else {
          return widgetUpdate(cache, result);
        }
      }

      return updateOnData;
    }
    return null;
  }
}

// ObservableQuery options
class WatchQueryOptions extends QueryOptions {
  WatchQueryOptions({
    @Deprecated('The "document" option has been deprecated, use "documentNode" instead')
        String document,
    DocumentNode documentNode,
    Map<String, dynamic> variables,
    FetchPolicy fetchPolicy,
    ErrorPolicy errorPolicy,
    Object optimisticResult,
    int pollInterval,
    this.fetchResults = false,
    this.eagerlyFetchResults,
    Map<String, dynamic> context,
  }) : super(
          // ignore: deprecated_member_use_from_same_package
          document: document,
          documentNode: documentNode,
          variables: variables,
          fetchPolicy: fetchPolicy,
          errorPolicy: errorPolicy,
          pollInterval: pollInterval,
          context: context,
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
    if (a.documentNode != b.documentNode) {
      return true;
    }

    if (a.policies != b.policies) {
      return true;
    }

    if (a.pollInterval != b.pollInterval) {
      return true;
    }

    if (a.fetchResults != b.fetchResults) {
      return true;
    }

    // compare variables last, because maps take more time
    return areDifferentVariables(a.variables, b.variables);
  }
}

/// merge fetchMore result data with earlier result data
typedef dynamic UpdateQuery(
  dynamic previousResultData,
  dynamic fetchMoreResultData,
);

/// options for fetchmore operations
class FetchMoreOptions {
  FetchMoreOptions({
    @Deprecated('The "document" option has been deprecated, use "documentNode" instead')
        String document,
    DocumentNode documentNode,
    this.variables = const <String, dynamic>{},
    @required this.updateQuery,
  })  : assert(
          // ignore: deprecated_member_use_from_same_package
          _mutuallyExclusive(document, documentNode),
          '"document" or "documentNode" options are mutually exclusive.',
        ),
        assert(updateQuery != null),
        this.documentNode =
            // ignore: deprecated_member_use_from_same_package
            documentNode ?? document != null ? parseString(document) : null;

  DocumentNode documentNode;

  /// A string representation of [documentNode]
  @Deprecated(
      'The "document" option has been deprecated, use "documentNode" instead')
  String get document => printNode(documentNode);

  @Deprecated(
      'The "document" option has been deprecated, use "documentNode" instead')
  set document(value) {
    documentNode = parseString(value);
  }

  final Map<String, dynamic> variables;

  /// Strategy for merging the fetchMore result data
  /// with the result data already in the cache
  UpdateQuery updateQuery;
}

bool _mutuallyExclusive(
  Object a,
  Object b, {
  bool required = false,
}) =>
    (!required && a == null && b == null) ||
    (a != null && b == null) ||
    (a == null && b != null);
