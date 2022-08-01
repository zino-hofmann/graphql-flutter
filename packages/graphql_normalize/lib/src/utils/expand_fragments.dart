import 'package:gql/ast.dart';

/// Adds fragment fields to selections if fragment type matches [typename]
/// and deeply merges nested field nodes.
List<FieldNode> expandFragments({
  required String? typename,
  required SelectionSetNode selectionSet,
  required Map<String, FragmentDefinitionNode> fragmentMap,
  required Map<String, Set<String>> possibleTypes,
}) {
  final fieldNodes = <FieldNode>[];

  for (var selectionNode in selectionSet.selections) {
    if (selectionNode is FieldNode) {
      fieldNodes.add(selectionNode);
      continue;
    }
    if (typename == null) {
      continue;
    }
    String fragmentOnName;
    SelectionSetNode fragmentSelectionSet;
    if (selectionNode is InlineFragmentNode) {
      fragmentOnName = selectionNode.typeCondition?.on.name.value ?? typename;
      fragmentSelectionSet = selectionNode.selectionSet;
    } else if (selectionNode is FragmentSpreadNode) {
      final fragment = fragmentMap[selectionNode.name.value];
      if (fragment == null) {
        throw Exception('Missing fragment ${selectionNode.name.value}');
      }
      fragmentOnName = fragment.typeCondition.on.name.value;
      fragmentSelectionSet = fragment.selectionSet;
    } else {
      throw (FormatException('Unknown selection node type'));
    }
    // We'll add the fields if
    //  - We know the current type (typename != null) AND
    //    - If the fragment and current type are the same (fragmentOnName == typename) OR
    //    - the current type is a type of the fragment target
    if (fragmentOnName == typename ||
        possibleTypes[fragmentOnName]?.contains(typename) == true) {
      fieldNodes.addAll(
        expandFragments(
          typename: typename,
          selectionSet: fragmentSelectionSet,
          fragmentMap: fragmentMap,
          possibleTypes: possibleTypes,
        ),
      );
    }
  }
  return List.from(_mergeSelections(fieldNodes));
}

/// Deeply merges field nodes
List<SelectionNode> _mergeSelections(
  List<SelectionNode> selections,
) =>
    selections
        .fold<Map<String, SelectionNode>>(
          {},
          (selectionMap, selection) {
            if (selection is FieldNode) {
              final key = selection.alias?.value ?? selection.name.value;
              if (selection.selectionSet == null) {
                return selectionMap..[key] = selection;
              } else if (!selectionMap.containsKey(key)) {
                return selectionMap..[key] = selection;
              } else {
                final existingNode = selectionMap[key];
                final existingSelections = existingNode is FieldNode &&
                        existingNode.selectionSet != null
                    ? existingNode.selectionSet!.selections
                    : <SelectionNode>[];
                final mergedField = FieldNode(
                  name: selection.name,
                  alias: selection.alias,
                  arguments: selection.arguments,
                  selectionSet: SelectionSetNode(
                    selections: _mergeSelections(
                      [
                        ...existingSelections,
                        ...selection.selectionSet!.selections
                      ],
                    ),
                  ),
                );
                return selectionMap..[key] = mergedField;
              }
            } else {
              return selectionMap..[selection.hashCode.toString()] = selection;
            }
          },
        )
        .values
        .toList();
