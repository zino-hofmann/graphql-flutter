import 'package:graphql/src/cache/cache.dart';
import 'package:meta/meta.dart';

import 'package:gql/ast.dart';
import 'package:gql_exec/gql_exec.dart';

import 'package:graphql/client.dart';
import 'package:graphql/internal.dart';
import 'package:graphql/src/core/raw_operation_data.dart';
import 'package:graphql/src/utilities/helpers.dart';
import 'package:graphql/src/core/policies.dart';

/// Base options.
class BaseOptions extends RawOperationData {
  BaseOptions({
    @required DocumentNode document,
    Map<String, dynamic> variables,
    this.policies,
    this.context,
    this.optimisticResult,
  }) : super(
          document: document,
          variables: variables,
        );

  /// An optimistic result to eagerly add to the operation stream
  Object optimisticResult;

  /// Specifies the [Policies] to be used during execution.
  Policies policies;

  FetchPolicy get fetchPolicy => policies.fetch;

  ErrorPolicy get errorPolicy => policies.error;

  /// Context to be passed to link execution chain.
  Context context;

  // TODO consider inverting this relationship
  /// Resolve these options into a request
  Request get asRequest => Request(
        operation: Operation(
          document: document,
          operationName: operationName,
        ),
        variables: variables,
        context: context ?? Context(),
      );
}

/// Query options.
class QueryOptions extends BaseOptions {
  QueryOptions({
    @required DocumentNode document,
    Map<String, dynamic> variables,
    FetchPolicy fetchPolicy,
    ErrorPolicy errorPolicy,
    Object optimisticResult,
    this.pollInterval,
    Context context,
  }) : super(
          policies: Policies(fetch: fetchPolicy, error: errorPolicy),
          document: document,
          variables: variables,
          context: context,
          optimisticResult: optimisticResult,
        );

  /// The time interval (in milliseconds) on which this query should be
  /// re-fetched from the server.
  int pollInterval;
}

typedef OnMutationCompleted = void Function(dynamic data);
typedef OnMutationUpdate = void Function(
  GraphQLDataProxy cache,
  QueryResult result,
);
typedef OnError = void Function(OperationException error);

/// Mutation options
class MutationOptions extends BaseOptions {
  MutationOptions({
    @required DocumentNode document,
    Map<String, dynamic> variables,
    FetchPolicy fetchPolicy,
    ErrorPolicy errorPolicy,
    Context context,
    this.onCompleted,
    this.update,
    this.onError,
  }) : super(
          policies: Policies(fetch: fetchPolicy, error: errorPolicy),
          document: document,
          variables: variables,
          context: context,
        );

  OnMutationCompleted onCompleted;
  OnMutationUpdate update;
  OnError onError;
}

class MutationCallbacks {
  final MutationOptions options;
  final GraphQLCache cache;
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
        if (!result.isLoading && !result.isOptimistic) {
          return options.onCompleted(result.data);
        }
      };
    }
    return null;
  }

  OnData get onError {
    if (options.onError != null) {
      return (QueryResult result) {
        if (!result.isLoading &&
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
    cache.recordOptimisticTransaction(
      (GraphQLDataProxy cache) {
        options.update(cache, result);
        return cache;
      },
      patchId,
    );
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
        if (result.isOptimistic) {
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
    @required DocumentNode document,
    Map<String, dynamic> variables,
    FetchPolicy fetchPolicy,
    ErrorPolicy errorPolicy,
    Object optimisticResult,
    int pollInterval,
    this.fetchResults = false,
    this.eagerlyFetchResults,
    Context context,
  }) : super(
          document: document,
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
    if (a.document != b.document) {
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

  WatchQueryOptions copy() => WatchQueryOptions(
        document: document,
        variables: variables,
        fetchPolicy: fetchPolicy,
        errorPolicy: errorPolicy,
        optimisticResult: optimisticResult,
        pollInterval: pollInterval,
        fetchResults: fetchResults,
        eagerlyFetchResults: eagerlyFetchResults,
        context: context,
      );
}

/// merge fetchMore result data with earlier result data
typedef dynamic UpdateQuery(
  dynamic previousResultData,
  dynamic fetchMoreResultData,
);
