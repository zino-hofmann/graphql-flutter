import 'package:gql/ast.dart';

import 'package:graphql_normalize/src/utils/field_key.dart';
import 'package:graphql_normalize/src/utils/expand_fragments.dart';
import 'package:graphql_normalize/src/utils/exceptions.dart';
import 'package:graphql_normalize/src/config/normalization_config.dart';
import 'package:graphql_normalize/src/utils/is_dangling_reference.dart';
import 'package:graphql_normalize/src/policies/field_policy.dart';

/// Returns a denormalized object for a given [SelectionSetNode].
///
/// This is called recursively as the AST is traversed.
Object? denormalizeNode({
  required SelectionSetNode? selectionSet,
  required Object? dataForNode,
  required NormalizationConfig config,
}) {
  if (dataForNode == null) return null;

  if (dataForNode is List) {
    return dataForNode
        .where((data) => !isDanglingReference(data, config))
        .map(
          (data) => denormalizeNode(
            selectionSet: selectionSet,
            dataForNode: data,
            config: config,
          ),
        )
        .toList();
  }

  // If this is a leaf node, return the data
  if (selectionSet == null) return dataForNode;

  if (dataForNode is Map) {
    final denormalizedData = dataForNode.containsKey(config.referenceKey)
        ? config.read(dataForNode[config.referenceKey] as String) ?? {}
        : Map<String, dynamic>.from(dataForNode);

    final typename = denormalizedData['__typename'] as String?;
    final typePolicy = config.typePolicies[typename];

    final subNodes = expandFragments(
      typename: typename,
      selectionSet: selectionSet,
      fragmentMap: config.fragmentMap,
      possibleTypes: config.possibleTypes,
    );

    final result = subNodes.fold<Map<String, dynamic>>(
      {},
      (result, fieldNode) {
        final fieldPolicy =
            (typePolicy?.fields ?? const {})[fieldNode.name.value];
        final policyCanRead = fieldPolicy?.read != null;

        final fieldName = FieldKey(
          fieldNode,
          config.variables,
          fieldPolicy,
        ).toString();

        final resultKey = fieldNode.alias?.value ?? fieldNode.name.value;

        /// If the policy can't read,
        /// and the key is missing from the data,
        /// we have partial data
        if (!policyCanRead && !denormalizedData.containsKey(fieldName)) {
          if (config.allowPartialData) {
            return result;
          }
          throw PartialDataException(path: [resultKey]);
        }

        try {
          if (policyCanRead) {
            // we can denormalize missing fields with policies
            // because they may be purely virtualized
            return result
              ..[resultKey] = fieldPolicy!.read!(
                denormalizedData[fieldName],
                FieldFunctionOptions(
                  field: fieldNode,
                  config: config,
                ),
              );
          }
          return result
            ..[resultKey] = denormalizeNode(
              selectionSet: fieldNode.selectionSet,
              dataForNode: denormalizedData[fieldName],
              config: config,
            );
        } on PartialDataException catch (e) {
          throw PartialDataException(path: [fieldName, ...e.path]);
        }
      },
    );

    return result.isEmpty ? null : result;
  }

  throw Exception(
    'There are sub-selections on this node, but the data is not null, an Array, or a Map',
  );
}
