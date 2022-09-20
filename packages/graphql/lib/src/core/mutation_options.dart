import 'dart:async';
import 'package:graphql/client.dart';
import 'package:graphql/src/core/_base_options.dart';

import 'package:gql/ast.dart';
import 'package:graphql/src/core/result_parser.dart';

import 'package:meta/meta.dart';

typedef OnMutationCompleted = FutureOr<void> Function(
    Map<String, dynamic>? data);
typedef OnMutationUpdate<TParsed> = FutureOr<void> Function(
  GraphQLDataProxy cache,
  QueryResult<TParsed>? result,
);
typedef OnError = FutureOr<void> Function(OperationException? error);

@immutable
class MutationOptions<TParsed extends Object?> extends BaseOptions<TParsed> {
  MutationOptions({
    required DocumentNode document,
    String? operationName,
    Map<String, dynamic> variables = const {},
    FetchPolicy? fetchPolicy,
    ErrorPolicy? errorPolicy,
    CacheRereadPolicy? cacheRereadPolicy,
    Context? context,
    Object? optimisticResult,
    this.onCompleted,
    this.update,
    this.onError,
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

  final OnMutationCompleted? onCompleted;
  final OnMutationUpdate<TParsed>? update;
  final OnError? onError;

  @override
  List<Object?> get properties => [
        ...super.properties,
        onCompleted,
        update,
        onError,
      ];

  MutationOptions<TParsed> copyWithPolicies(Policies policies) =>
      MutationOptions(
        document: document,
        operationName: operationName,
        variables: variables,
        fetchPolicy: policies.fetch,
        errorPolicy: policies.error,
        cacheRereadPolicy: policies.cacheReread,
        context: context,
        optimisticResult: optimisticResult,
        onCompleted: onCompleted,
        update: update,
        onError: onError,
        parserFn: parserFn,
      );

  WatchQueryOptions<TParsed> asWatchQueryOptions() =>
      WatchQueryOptions<TParsed>(
        document: document,
        operationName: operationName,
        variables: variables,
        fetchPolicy: fetchPolicy,
        errorPolicy: errorPolicy,
        cacheRereadPolicy: cacheRereadPolicy,
        fetchResults: false,
        context: context,
        parserFn: parserFn,
      );
}

/// Handles execution of mutation `update`, `onCompleted`, and `onError` callbacks
class MutationCallbackHandler<TParsed> {
  final MutationOptions<TParsed> options;
  final GraphQLCache cache;
  final String queryId;

  MutationCallbackHandler({
    required this.options,
    required this.cache,
    required this.queryId,
  });

  // callbacks will be called against each result in the stream,
  // which should then rebroadcast queries with the appropriate optimism
  Iterable<OnData<TParsed>> get callbacks => <OnData<TParsed>?>[
        onCompleted,
        update,
        onError
      ].whereType<OnData<TParsed>>();

  // Todo: probably move this to its own class
  OnData<TParsed>? get onCompleted {
    if (options.onCompleted != null) {
      return (QueryResult? result) {
        if (!result!.isLoading && !result.isOptimistic) {
          return options.onCompleted!(result.data);
        }
      };
    }
    return null;
  }

  OnData<TParsed>? get onError {
    if (options.onError != null) {
      return (QueryResult? result) {
        if (!result!.isLoading &&
            result.hasException &&
            options.errorPolicy != ErrorPolicy.ignore) {
          return options.onError!(result.exception);
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
  void _optimisticUpdate(QueryResult<TParsed>? result) {
    final String patchId = _patchId;
    // this is also done in query_manager, but better safe than sorry
    cache.recordOptimisticTransaction(
      (GraphQLDataProxy cache) {
        options.update!(cache, result);
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
  OnData<TParsed>? get update {
    if (options.update != null) {
      // dereference all variables that might be needed if the widget is disposed
      final OnMutationUpdate<TParsed>? widgetUpdate = options.update;
      final OnData<TParsed> optimisticUpdate = _optimisticUpdate;

      // wrap update logic to handle optimism
      FutureOr<void> updateOnData(QueryResult<TParsed>? result) {
        if (result!.isOptimistic) {
          return optimisticUpdate(result);
        } else {
          return widgetUpdate!(cache, result);
        }
      }

      return updateOnData;
    }
    return null;
  }
}
