import 'package:gql/ast.dart';

OperationDefinitionNode getOperationNode(DocumentNode doc) {
  if (doc.definitions == null || doc.definitions.isEmpty) return null;

  final operations = doc.definitions.whereType<OperationDefinitionNode>();

  if (operations.isEmpty) return null;

  return operations.last;
}

bool isSubscription(DocumentNode doc) {
  final operation = getOperationNode(doc);

  if (operation == null) throw ArgumentError('Document must contain an operation');

  return operation.type == OperationType.subscription;
}

String getOperationName(DocumentNode doc) {
  final operation = getOperationNode(doc);

  if (operation == null) throw ArgumentError('Document must contain an operation');

  if (operation.name == null) return null;

  return operation.name.value;
}
