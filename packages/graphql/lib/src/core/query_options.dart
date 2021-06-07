// ignore_for_file: deprecated_member_use_from_same_package
import 'package:graphql/src/core/_base_options.dart';
import 'package:graphql/src/utilities/helpers.dart';

import 'package:gql/ast.dart';
import 'package:gql_exec/gql_exec.dart';

import 'package:graphql/client.dart';
import 'package:graphql/src/core/policies.dart';

/// Query options.
class QueryOptions extends BaseOptions {
  QueryOptions({
    required DocumentNode document,
    String? operationName,
    Map<String, dynamic> variables = const {},
    FetchPolicy? fetchPolicy,
    ErrorPolicy? errorPolicy,
    CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    this.pollInterval,
    Context? context,
  }) : super(
          fetchPolicy: fetchPolicy,
          errorPolicy: errorPolicy,
          cacheRereadPolicy: cacheRereadPolicy,
          document: document,
          operationName: operationName,
          variables: variables,
          context: context,
          optimisticResult: optimisticResult,
        );

  /// The time interval on which this query should be re-fetched from the server.
  Duration? pollInterval;

  @override
  List<Object?> get properties => [...super.properties, pollInterval];

  WatchQueryOptions asWatchQueryOptions({bool fetchResults = true}) =>
      WatchQueryOptions(
        document: document,
        operationName: operationName,
        variables: variables,
        fetchPolicy: fetchPolicy,
        errorPolicy: errorPolicy,
        cacheRereadPolicy: cacheRereadPolicy,
        pollInterval: pollInterval,
        fetchResults: fetchResults,
        context: context,
        optimisticResult: optimisticResult,
      );
}

class SubscriptionOptions extends BaseOptions {
  SubscriptionOptions({
    required DocumentNode document,
    String? operationName,
    Map<String, dynamic> variables = const {},
    FetchPolicy? fetchPolicy,
    ErrorPolicy? errorPolicy,
    CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Context? context,
  }) : super(
          fetchPolicy: fetchPolicy,
          errorPolicy: errorPolicy,
          cacheRereadPolicy: cacheRereadPolicy,
          document: document,
          operationName: operationName,
          variables: variables,
          context: context,
          optimisticResult: optimisticResult,
        );

  /// An optimistic first result to eagerly add to the subscription stream
  Object? optimisticResult;
}

class WatchQueryOptions extends QueryOptions {
  WatchQueryOptions({
    required DocumentNode document,
    String? operationName,
    Map<String, dynamic> variables = const {},
    FetchPolicy? fetchPolicy,
    ErrorPolicy? errorPolicy,
    CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Duration? pollInterval,
    this.fetchResults = false,
    this.carryForwardDataOnException = true,
    bool? eagerlyFetchResults,
    Context? context,
  })  : eagerlyFetchResults = eagerlyFetchResults ?? fetchResults,
        super(
          document: document,
          operationName: operationName,
          variables: variables,
          fetchPolicy: fetchPolicy,
          errorPolicy: errorPolicy,
          cacheRereadPolicy: cacheRereadPolicy,
          pollInterval: pollInterval,
          context: context,
          optimisticResult: optimisticResult,
        );

  /// Whether or not to fetch results
  bool fetchResults;

  /// Whether to [fetchResults] immediately on instantiation.
  /// Defaults to [fetchResults].
  bool eagerlyFetchResults;

  /// carry forward previous data in the result of errors and no data.
  /// defaults to `true`.
  bool carryForwardDataOnException;

  @override
  List<Object?> get properties =>
      [...super.properties, fetchResults, eagerlyFetchResults];

  WatchQueryOptions copy() => WatchQueryOptions(
        document: document,
        operationName: operationName,
        variables: variables,
        fetchPolicy: fetchPolicy,
        errorPolicy: errorPolicy,
        cacheRereadPolicy: cacheRereadPolicy,
        optimisticResult: optimisticResult,
        pollInterval: pollInterval,
        fetchResults: fetchResults,
        eagerlyFetchResults: eagerlyFetchResults,
        carryForwardDataOnException: carryForwardDataOnException,
        context: context,
      );
}

/// options for fetchMore operations
///
/// **NOTE**: with the addition of strict data structure checking in v4,
/// it is easy to make mistakes in writing [updateQuery].
///
/// To mitigate this, [FetchMoreOptions.partial] has been provided.
class FetchMoreOptions {
  FetchMoreOptions({
    this.document,
    this.variables = const {},
    required this.updateQuery,
  });

  /// Automatically merge the results of [updateQuery] into `previousResultData`.
  ///
  /// This is useful if you only want to, say, extract some list data
  /// from the newly fetched result, and don't want to worry about
  /// structural inconsistencies while merging.
  static FetchMoreOptions partial({
    DocumentNode? document,
    Map<String, dynamic> variables = const {},
    required UpdateQuery updateQuery,
  }) =>
      FetchMoreOptions(
        document: document,
        variables: variables,
        updateQuery: partialUpdater(updateQuery),
      );

  DocumentNode? document;

  Map<String, dynamic> variables;

  /// Strategy for merging the fetchMore result data
  /// with the result data already in the cache
  UpdateQuery updateQuery;

  /// Wrap an [UpdateQuery] in a [deeplyMergeLeft] of the `previousResultData`.
  static UpdateQuery partialUpdater(UpdateQuery update) =>
      (previous, fetched) => deeplyMergeLeft(
            [previous, update(previous, fetched)],
          );
}

/// merge fetchMore result data with earlier result data
typedef Map<String, dynamic>? UpdateQuery(
  Map<String, dynamic>? previousResultData,
  Map<String, dynamic>? fetchMoreResultData,
);

extension WithType on Request {
  OperationType get type {
    final definitions = operation.document.definitions
        .whereType<OperationDefinitionNode>()
        .toList();
    if (operation.operationName != null) {
      definitions.removeWhere(
        (node) => node.name!.value != operation.operationName,
      );
    }
    // TODO differentiate error types, add exception
    assert(definitions.length == 1);
    return definitions.first.type;
  }

  bool get isQuery => type == OperationType.query;
  bool get isMutation => type == OperationType.mutation;
  bool get isSubscription => type == OperationType.subscription;
}
