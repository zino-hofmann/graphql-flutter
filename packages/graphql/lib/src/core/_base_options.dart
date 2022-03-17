import 'package:collection/collection.dart';
import 'package:gql/ast.dart';

import 'package:graphql/client.dart';
import 'package:graphql/src/core/result_parser.dart';
import 'package:meta/meta.dart';

TParsed unprovidedParserFn<TParsed>(_d) => throw UnimplementedError(
      "Please provide a parser function to support result parsing.",
    );

/// TODO refactor into [Request] container
/// Base options.
@immutable
abstract class BaseOptions<TParsed extends Object?> {
  BaseOptions({
    required this.document,
    this.variables = const {},
    this.operationName,
    ResultParserFn<TParsed>? parserFn,
    Context? context,
    FetchPolicy? fetchPolicy,
    ErrorPolicy? errorPolicy,
    CacheRereadPolicy? cacheRereadPolicy,
    this.optimisticResult,
  })  : policies = Policies(
          fetch: fetchPolicy,
          error: errorPolicy,
          cacheReread: cacheRereadPolicy,
        ),
        context = context ?? Context(),
        parserFn = parserFn ?? unprovidedParserFn;

  /// Document containing at least one [OperationDefinitionNode]
  final DocumentNode document;

  /// Name of the executable definition
  ///
  /// Must be specified if [document] contains more than one [OperationDefinitionNode]
  final String? operationName;

  /// A map going from variable name to variable value, where the variables are used
  /// within the GraphQL query.
  final Map<String, dynamic> variables;

  /// An optimistic result to eagerly add to the operation stream
  final Object? optimisticResult;

  /// Specifies the [Policies] to be used during execution.
  final Policies policies;

  FetchPolicy? get fetchPolicy => policies.fetch;

  ErrorPolicy? get errorPolicy => policies.error;

  CacheRereadPolicy? get cacheRereadPolicy => policies.cacheReread;

  /// Context to be passed to link execution chain.
  final Context context;

  final ResultParserFn<TParsed> parserFn;

  // TODO consider inverting this relationship
  /// Resolve these options into a request
  Request get asRequest => Request(
        operation: Operation(
          document: document,
          operationName: operationName,
        ),
        variables: variables,
        context: context,
      );

  @protected
  List<Object?> get properties => [
        document,
        operationName,
        variables,
        optimisticResult,
        policies,
        context,
        parserFn,
      ];

  OperationType get type {
    final definitions =
        document.definitions.whereType<OperationDefinitionNode>().toList();
    if (operationName != null) {
      definitions.removeWhere(
        (node) => node.name!.value != operationName,
      );
    }
    // TODO differentiate error types, add exception
    assert(definitions.length == 1);
    return definitions.first.type;
  }

  bool get isQuery => type == OperationType.query;
  bool get isMutation => type == OperationType.mutation;
  bool get isSubscription => type == OperationType.subscription;

  /// [properties] based deep equality check
  operator ==(Object other) =>
      identical(this, other) ||
      (other is BaseOptions &&
          runtimeType == other.runtimeType &&
          const ListEquality<Object?>(
            DeepCollectionEquality(),
          ).equals(
            other.properties,
            properties,
          ));

  @override
  int get hashCode => const ListEquality<Object?>(
        DeepCollectionEquality(),
      ).hash(properties);

  QueryResult<TParsed> createResult({
    Map<String, dynamic>? data,
    OperationException? exception,
    Context context = const Context(),
    required QueryResultSource source,
  }) =>
      QueryResult.internal(
        parserFn: parserFn,
        data: data,
        exception: exception,
        context: context,
        source: source,
      );
}
