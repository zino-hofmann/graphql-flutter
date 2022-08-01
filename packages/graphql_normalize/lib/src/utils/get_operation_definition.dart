import 'package:gql/ast.dart';

/// Returns the AST Node for the GraphQL Operation.
OperationDefinitionNode getOperationDefinition(
  DocumentNode document,
  String? operationName,
) {
  if (operationName != null) {
    return document.definitions
        .whereType<OperationDefinitionNode>()
        .firstWhere((definition) => definition.name?.value == operationName);
  } else {
    return document.definitions.whereType<OperationDefinitionNode>().first;
  }
}
