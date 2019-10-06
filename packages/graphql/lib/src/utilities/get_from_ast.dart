import 'package:gql/ast.dart';

List<OperationDefinitionNode> getOperationNodes(DocumentNode doc) {
  if (doc.definitions == null) return [];

  return doc.definitions.whereType<OperationDefinitionNode>().toList();
}

String getLastOperationName(DocumentNode doc) {
  final operations = getOperationNodes(doc);

  if (operations.isEmpty) return null;

  return operations.last?.name?.value;
}

bool isOfType(
  OperationType operationType,
  DocumentNode doc,
  String operationName,
) {
  final operations = getOperationNodes(doc);

  if (operationName == null) {
    if (operations.length > 1) return false;

    return operations.any(
      (op) => op.type == operationType,
    );
  }

  return operations.any(
    (op) => op.name?.value == operationName && op.type == operationType,
  );
}
