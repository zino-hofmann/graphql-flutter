import 'package:graphql/src/cache/cache.dart';
import 'package:graphql/src/core/_base_options.dart';
import 'package:graphql/src/core/_data_class.dart';
import 'package:meta/meta.dart';

import 'package:gql/ast.dart';
import 'package:gql_exec/gql_exec.dart';

import 'package:graphql/client.dart';
import 'package:graphql/internal.dart';
import 'package:graphql/src/utilities/helpers.dart';
import 'package:graphql/src/core/policies.dart';

/// Query options.
class QueryOptions extends BaseOptions {
  QueryOptions({
    @required DocumentNode document,
    String operationName,
    Map<String, dynamic> variables,
    FetchPolicy fetchPolicy,
    ErrorPolicy errorPolicy,
    Object optimisticResult,
    this.pollInterval,
    Context context,
  }) : super(
          fetchPolicy: fetchPolicy,
          errorPolicy: errorPolicy,
          document: document,
          operationName: operationName,
          variables: variables,
          context: context,
          optimisticResult: optimisticResult,
        );

  /// The time interval (in milliseconds) on which this query should be
  /// re-fetched from the server.
  final int pollInterval;

  @override
  List<Object> get properties => [...super.properties, pollInterval];
}

extension on QueryOptions {
  QueryOptions copyWith({
    DocumentNode document,
    String operationName,
    Map<String, dynamic> variables,
    Context context,
    FetchPolicy fetchPolicy,
    ErrorPolicy errorPolicy,
    Object optimisticResult,
    int pollInterval,
  }) =>
      QueryOptions(
        document: document ?? this.document,
        operationName: operationName ?? this.operationName,
        variables: variables ?? this.variables,
        context: context ?? this.context,
        fetchPolicy: fetchPolicy ?? this.fetchPolicy,
        errorPolicy: errorPolicy ?? this.errorPolicy,
        optimisticResult: optimisticResult ?? this.optimisticResult,
        pollInterval: pollInterval ?? this.pollInterval,
      );
}

class SubscriptionOptions extends BaseOptions {
  SubscriptionOptions({
    @required DocumentNode document,
    String operationName,
    Map<String, dynamic> variables,
    FetchPolicy fetchPolicy,
    ErrorPolicy errorPolicy,
    Object optimisticResult,
    Context context,
  }) : super(
          fetchPolicy: fetchPolicy,
          errorPolicy: errorPolicy,
          document: document,
          operationName: operationName,
          variables: variables,
          context: context,
          optimisticResult: optimisticResult,
        );

  SubscriptionOptions copyWith({
    DocumentNode document,
    String operationName,
    Map<String, dynamic> variables,
    Context context,
    FetchPolicy fetchPolicy,
    ErrorPolicy errorPolicy,
    Object optimisticResult,
  }) =>
      SubscriptionOptions(
        document: document ?? this.document,
        operationName: operationName ?? this.operationName,
        variables: variables ?? this.variables,
        context: context ?? this.context,
        fetchPolicy: fetchPolicy ?? this.fetchPolicy,
        errorPolicy: errorPolicy ?? this.errorPolicy,
        optimisticResult: optimisticResult ?? this.optimisticResult,
      );
}

/// Mutation options

// ObservableQuery options

class WatchQueryOptions extends QueryOptions {
  WatchQueryOptions({
    @required DocumentNode document,
    String operationName,
    Map<String, dynamic> variables,
    FetchPolicy fetchPolicy,
    ErrorPolicy errorPolicy,
    Object optimisticResult,
    int pollInterval,
    this.fetchResults = false,
    bool eagerlyFetchResults,
    Context context,
  })  : eagerlyFetchResults = eagerlyFetchResults ?? fetchResults,
        super(
          document: document,
          operationName: operationName,
          variables: variables,
          fetchPolicy: fetchPolicy,
          errorPolicy: errorPolicy,
          pollInterval: pollInterval,
          context: context,
          optimisticResult: optimisticResult,
        );

  /// Whether or not to fetch results
  final bool fetchResults;

  final bool eagerlyFetchResults;

  @override
  List<Object> get properties =>
      [...super.properties, fetchResults, eagerlyFetchResults];

  WatchQueryOptions copyWith({
    DocumentNode document,
    String operationName,
    Map<String, dynamic> variables,
    Context context,
    FetchPolicy fetchPolicy,
    ErrorPolicy errorPolicy,
    Object optimisticResult,
    int pollInterval,
    bool fetchResults,
    bool eagerlyFetchResults,
  }) =>
      WatchQueryOptions(
        document: document ?? this.document,
        operationName: operationName ?? this.operationName,
        variables: variables ?? this.variables,
        context: context ?? this.context,
        fetchPolicy: fetchPolicy ?? this.fetchPolicy,
        errorPolicy: errorPolicy ?? this.errorPolicy,
        optimisticResult: optimisticResult ?? this.optimisticResult,
        pollInterval: pollInterval ?? this.pollInterval,
        fetchResults: fetchResults ?? this.fetchResults,
        eagerlyFetchResults: eagerlyFetchResults ?? this.eagerlyFetchResults,
      );
}

/// merge fetchMore result data with earlier result data
typedef dynamic UpdateQuery(
  dynamic previousResultData,
  dynamic fetchMoreResultData,
);
