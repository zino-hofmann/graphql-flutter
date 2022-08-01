import 'package:gql/ast.dart';

class AddTypenameVisitor extends TransformingVisitor {
  @override
  FieldNode visitFieldNode(FieldNode node) {
    if (node.selectionSet == null) {
      return node;
    }

    final hasTypename = node.selectionSet!.selections
        .whereType<FieldNode>()
        .any((node) => node.name.value == '__typename');

    if (hasTypename) return node;

    return FieldNode(
      name: node.name,
      alias: node.alias,
      arguments: node.arguments,
      directives: node.directives,
      selectionSet: SelectionSetNode(
        selections: <SelectionNode>[
          FieldNode(
            name: NameNode(value: '__typename'),
          ),
          ...node.selectionSet!.selections,
        ],
      ),
    );
  }

  @override
  FragmentDefinitionNode visitFragmentDefinitionNode(
    FragmentDefinitionNode node,
  ) {
    final hasTypename = node.selectionSet.selections
        .whereType<FieldNode>()
        .any((node) => node.name.value == '__typename');

    if (hasTypename) return node;

    return FragmentDefinitionNode(
      name: node.name,
      typeCondition: node.typeCondition,
      directives: node.directives,
      selectionSet: SelectionSetNode(
        selections: <SelectionNode>[
          FieldNode(
            name: NameNode(value: '__typename'),
          ),
          ...node.selectionSet.selections,
        ],
      ),
    );
  }

  @override
  OperationDefinitionNode visitOperationDefinitionNode(
    OperationDefinitionNode node,
  ) {
    // Subscriptions can only have a single root type
    // https://spec.graphql.org/June2018/#example-2353b
    if (node.type == OperationType.subscription) {
      return node;
    }

    final hasTypename = node.selectionSet.selections
        .whereType<FieldNode>()
        .any((node) => node.name.value == '__typename');

    if (hasTypename) return node;

    return OperationDefinitionNode(
      type: node.type,
      name: node.name,
      variableDefinitions: node.variableDefinitions,
      directives: node.directives,
      selectionSet: SelectionSetNode(
        selections: <SelectionNode>[
          FieldNode(
            name: NameNode(value: '__typename'),
          ),
          ...node.selectionSet.selections,
        ],
      ),
    );
  }
}
