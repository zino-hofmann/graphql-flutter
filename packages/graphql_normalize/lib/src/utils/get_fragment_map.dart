import 'package:gql/ast.dart';

Map<String, FragmentDefinitionNode> getFragmentMap(DocumentNode document) => {
      for (var fragmentDefinition
          in document.definitions.whereType<FragmentDefinitionNode>())
        fragmentDefinition.name.value: fragmentDefinition
    };

FragmentDefinitionNode findFragmentInFragmentMap({
  required Map<String, FragmentDefinitionNode> fragmentMap,
  String? fragmentName,
}) {
  if (fragmentName == null) {
    if (fragmentMap.isEmpty) {
      throw Exception('Found no fragment definitions in document.');
    }
    if (fragmentMap.length > 1) {
      throw Exception(
        'Multiple fragments defined, but no fragmentName provided',
      );
    }
    return fragmentMap.values.first;
  }
  final lookupFragment = fragmentMap[fragmentName];
  if (lookupFragment == null) {
    throw Exception(
      'Fragment "$fragmentName" not found',
    );
  }
  return lookupFragment;
}
