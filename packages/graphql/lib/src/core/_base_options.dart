import 'package:graphql/src/core/_data_class.dart';
import 'package:meta/meta.dart';

import 'package:gql/ast.dart';
import 'package:gql_exec/gql_exec.dart';

import 'package:graphql/client.dart';
import 'package:graphql/src/core/policies.dart';

/// Base options.
@immutable
class BaseOptions extends DataClass {
  BaseOptions({
    @required this.document,
    this.operationName,
    this.variables,
    Context context,
    FetchPolicy fetchPolicy,
    ErrorPolicy errorPolicy,
    this.optimisticResult,
  })  : policies = Policies(fetch: fetchPolicy, error: errorPolicy),
        context = context ?? Context();

  /// Document containing at least one [OperationDefinitionNode]
  final DocumentNode document;

  /// Name of the executable definition
  ///
  /// Must be specified if [document] contains more than one [OperationDefinitionNode]
  final String operationName;

  /// A map going from variable name to variable value, where the variables are used
  /// within the GraphQL query.
  final Map<String, dynamic> variables;

  /// An optimistic result to eagerly add to the operation stream
  final Object optimisticResult;

  /// Specifies the [Policies] to be used during execution.
  final Policies policies;

  FetchPolicy get fetchPolicy => policies.fetch;

  ErrorPolicy get errorPolicy => policies.error;

  /// Context to be passed to link execution chain.
  final Context context;

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

  @override
  List<Object> get properties => [
        document,
        operationName,
        variables,
        optimisticResult,
        policies,
        context,
      ];
}
