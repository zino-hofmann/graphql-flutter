import 'dart:async';

import 'package:graphql/src/core/_base_options.dart';
import 'package:graphql/src/core/result_parser.dart';
import 'package:graphql/src/utilities/helpers.dart';

import 'package:gql/ast.dart';

import 'package:graphql/client.dart';
import 'package:meta/meta.dart';

typedef OnQueryComplete = FutureOr<void> Function(Map<String, dynamic>? data);

typedef OnQueryError = FutureOr<void> Function(OperationException? error);

/// Query options.
@immutable
class QueryOptions<TParsed extends Object?> extends BaseOptions<TParsed> {
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
    ResultParserFn<TParsed>? parserFn,
    this.onComplete,
    this.onError,
  }) : super(
          fetchPolicy: fetchPolicy,
          errorPolicy: errorPolicy,
          cacheRereadPolicy: cacheRereadPolicy,
          document: document,
          operationName: operationName,
          variables: variables,
          context: context,
          optimisticResult: optimisticResult,
          parserFn: parserFn,
        );

  final OnQueryComplete? onComplete;
  final OnQueryError? onError;

  /// The time interval on which this query should be re-fetched from the server.
  final Duration? pollInterval;

  @override
  List<Object?> get properties => [
        ...super.properties,
        pollInterval,
        onComplete,
        onError,
      ];

  QueryOptions<TParsed> withFetchMoreOptions(
    FetchMoreOptions fetchMoreOptions,
  ) =>
      QueryOptions<TParsed>(
        document: fetchMoreOptions.document ?? document,
        operationName: operationName,
        fetchPolicy: FetchPolicy.noCache,
        errorPolicy: errorPolicy,
        parserFn: parserFn,
        context: context,
        variables: {
          ...variables,
          ...fetchMoreOptions.variables,
        },
      );

  WatchQueryOptions<TParsed> asWatchQueryOptions({bool fetchResults = true}) =>
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
        parserFn: parserFn,
      );

  QueryOptions<TParsed> copyWithPolicies(Policies policies) => QueryOptions(
        document: document,
        operationName: operationName,
        variables: variables,
        fetchPolicy: policies.fetch,
        errorPolicy: policies.error,
        cacheRereadPolicy: policies.cacheReread,
        optimisticResult: optimisticResult,
        pollInterval: pollInterval,
        context: context,
        parserFn: parserFn,
      );
}

@immutable
class SubscriptionOptions<TParsed extends Object?>
    extends BaseOptions<TParsed> {
  SubscriptionOptions({
    required DocumentNode document,
    String? operationName,
    Map<String, dynamic> variables = const {},
    FetchPolicy? fetchPolicy,
    ErrorPolicy? errorPolicy,
    CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Context? context,
    ResultParserFn<TParsed>? parserFn,
  }) : super(
          fetchPolicy: fetchPolicy,
          errorPolicy: errorPolicy,
          cacheRereadPolicy: cacheRereadPolicy,
          document: document,
          operationName: operationName,
          variables: variables,
          context: context,
          optimisticResult: optimisticResult,
          parserFn: parserFn,
        );
  SubscriptionOptions<TParsed> copyWithPolicies(Policies policies) =>
      SubscriptionOptions(
        document: document,
        operationName: operationName,
        variables: variables,
        fetchPolicy: policies.fetch,
        errorPolicy: policies.error,
        cacheRereadPolicy: policies.cacheReread,
        optimisticResult: optimisticResult,
        context: context,
        parserFn: parserFn,
      );
}

@immutable
class WatchQueryOptions<TParsed extends Object?> extends QueryOptions<TParsed> {
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
    ResultParserFn<TParsed>? parserFn,
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
          parserFn: parserFn,
        );

  /// Whether or not to fetch results
  final bool fetchResults;

  /// Whether to [fetchResults] immediately on instantiation.
  /// Defaults to [fetchResults].
  final bool eagerlyFetchResults;

  /// carry forward previous data in the result of errors and no data.
  /// defaults to `true`.
  final bool carryForwardDataOnException;

  @override
  List<Object?> get properties => [
        ...super.properties,
        fetchResults,
        eagerlyFetchResults,
        carryForwardDataOnException,
      ];

  WatchQueryOptions<TParsed> copyWithFetchPolicy(
    FetchPolicy? fetchPolicy,
  ) =>
      WatchQueryOptions<TParsed>(
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
        parserFn: parserFn,
      );
  WatchQueryOptions<TParsed> copyWithPolicies(
    Policies policies,
  ) =>
      WatchQueryOptions<TParsed>(
        document: document,
        operationName: operationName,
        variables: variables,
        fetchPolicy: policies.fetch,
        errorPolicy: policies.error,
        cacheRereadPolicy: policies.cacheReread,
        optimisticResult: optimisticResult,
        pollInterval: pollInterval,
        fetchResults: fetchResults,
        eagerlyFetchResults: eagerlyFetchResults,
        carryForwardDataOnException: carryForwardDataOnException,
        context: context,
        parserFn: parserFn,
      );

  WatchQueryOptions<TParsed> copyWithPollInterval(Duration? pollInterval) =>
      WatchQueryOptions<TParsed>(
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
        parserFn: parserFn,
      );

  WatchQueryOptions<TParsed> copyWithVariables(
          Map<String, dynamic> variables) =>
      WatchQueryOptions<TParsed>(
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
        parserFn: parserFn,
      );

  WatchQueryOptions<TParsed> copyWithOptimisticResult(
          Object? optimisticResult) =>
      WatchQueryOptions<TParsed>(
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
        parserFn: parserFn,
      );
}

/// options for fetchMore operations
///
/// **NOTE**: with the addition of strict data structure checking in v4,
/// it is easy to make mistakes in writing [updateQuery].
///
/// To mitigate this, [FetchMoreOptions.partial] has been provided.
@immutable
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

  final DocumentNode? document;

  final Map<String, dynamic> variables;

  /// Strategy for merging the fetchMore result data
  /// with the result data already in the cache
  final UpdateQuery updateQuery;

  /// Wrap an [UpdateQuery] in a [deeplyMergeLeft] of the `previousResultData`.
  static UpdateQuery partialUpdater(UpdateQuery update) =>
      (previous, fetched) => deeplyMergeLeft(
            [previous, update(previous, fetched)],
          );
}

/// merge fetchMore result data with earlier result data
typedef UpdateQuery = Map<String, dynamic>? Function(
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

/// Handles execution of query callbacks
class QueryCallbackHandler<TParsed> {
  final QueryOptions<TParsed> options;

  QueryCallbackHandler({required this.options});

  Iterable<OnData<TParsed>> get callbacks {
    var callbacks = List<OnData<TParsed>?>.empty(growable: true);
    callbacks.addAll([onCompleted, onError]);
    // FIXME: can we remove the type in whereType?
    return callbacks.whereType<OnData<TParsed>>();
  }

  OnData<TParsed>? get onCompleted {
    if (options.onComplete != null) {
      return (QueryResult? result) {
        if (!result!.isLoading && !result.isOptimistic) {
          return options.onComplete!(result.data);
        }
      };
    }
    return null;
  }

  OnData<TParsed>? get onError {
    if (options.onError != null && options.errorPolicy != ErrorPolicy.ignore) {
      return (QueryResult? result) {
        if (!result!.isLoading && result.hasException) {
          return options.onError!(result.exception);
        }
      };
    }
    return null;
  }
}
