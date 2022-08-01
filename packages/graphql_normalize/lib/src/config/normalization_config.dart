import 'package:gql/ast.dart';

import 'package:graphql_normalize/src/policies/type_policy.dart';
import 'package:graphql_normalize/src/utils/resolve_data_id.dart';

class NormalizationConfig {
  final Map<String, dynamic>? Function(String dataId) read;

  /// Fragment or operation variables that parameterize the document.
  final Map<String, dynamic> variables;

  /// Mapping of `__typename` to custom [TypePolicy] to use, if any.
  final Map<String, TypePolicy> typePolicies;
  final String referenceKey;

  /// Mapping of fragment names to their definitions for spread resolution.
  final Map<String, FragmentDefinitionNode> fragmentMap;

  /// Resolves a data id [String] for a given object [Map],
  /// or returns `null` if the [Map] should not be normalized.
  final DataIdResolver? dataIdFromObject;

  /// Whether to add a `__typename` field to every selection set in the document.
  final bool addTypename;

  /// Whether to accept or return partial data.
  final bool allowPartialData;

  /// A map from an interface/union to possible types.
  final Map<String, Set<String>> possibleTypes;

  NormalizationConfig({
    required this.read,
    required this.variables,
    required this.typePolicies,
    required this.referenceKey,
    required this.fragmentMap,
    required this.dataIdFromObject,
    required this.addTypename,
    required this.allowPartialData,
    required this.possibleTypes,
  });
}
