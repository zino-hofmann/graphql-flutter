import 'package:gql/ast.dart';

import 'package:graphql_normalize/src/utils/resolve_data_id.dart';
import 'package:graphql_normalize/src/utils/field_key.dart';
import 'package:graphql_normalize/src/utils/expand_fragments.dart';
import 'package:graphql_normalize/src/utils/exceptions.dart';
import 'package:graphql_normalize/src/utils/deep_merge.dart';
import 'package:graphql_normalize/src/config/normalization_config.dart';
import 'package:graphql_normalize/src/policies/field_policy.dart';

/// Returns a normalized object for a given [SelectionSetNode].
///
/// This is called recursively as the AST is traversed.
Object? normalizeNode({
  required SelectionSetNode? selectionSet,
  required Object? dataForNode,
  required Object? existingNormalizedData,
  required NormalizationConfig config,
  required void Function(String dataId, Map<String, dynamic> value) write,
  bool root = false,
}) {
  if (dataForNode == null) return null;

  if (dataForNode is List) {
    return dataForNode
        .map((data) => normalizeNode(
              selectionSet: selectionSet,
              dataForNode: data,
              existingNormalizedData: null,
              config: config,
              write: write,
            ))
        .toList();
  }

  // If this is a leaf node, return the data
  if (selectionSet == null) return dataForNode;

  if (dataForNode is Map) {
    final dataId = resolveDataId(
      data: Map<String, dynamic>.from(dataForNode),
      typePolicies: config.typePolicies,
      dataIdFromObject: config.dataIdFromObject,
    );

    if (dataId != null) existingNormalizedData = config.read(dataId);

    final typename = dataForNode['__typename'] as String?;
    final typePolicy = config.typePolicies[typename];

    final subNodes = expandFragments(
      typename: typename,
      selectionSet: selectionSet,
      fragmentMap: config.fragmentMap,
      possibleTypes: config.possibleTypes,
    );

    final dataToMerge = <String, dynamic>{
      if (config.addTypename && typename != null) '__typename': typename,
      ...subNodes.fold({}, (data, field) {
        final fieldPolicy = (typePolicy?.fields ?? const {})[field.name.value];
        final policyCanMerge = fieldPolicy?.merge != null;
        final policyCanRead = fieldPolicy?.read != null;
        final fieldName = FieldKey(
          field,
          config.variables,
          fieldPolicy,
        ).toString();
        final existingFieldData = existingNormalizedData is Map
            ? existingNormalizedData[fieldName]
            : null;
        final inputKey = field.alias?.value ?? field.name.value;

        /// If the policy can't merge or read,
        /// And the key is missing from the data,
        /// we have partial data.
        ///
        /// We have to consider reads because maybe
        /// this is a virtualized field, and thus can't be written regardless
        if (!(policyCanMerge || policyCanRead) &&
            !dataForNode.containsKey(inputKey)) {
          // if partial data is accepted, we proceed as usual
          // and just write nulls where data is missing
          if (!config.allowPartialData) {
            throw PartialDataException(path: [inputKey]);
          }
        }

        try {
          final fieldData = normalizeNode(
            selectionSet: field.selectionSet,
            dataForNode: dataForNode[inputKey],
            existingNormalizedData: existingFieldData,
            config: config,
            write: write,
          );
          if (policyCanMerge) {
            return data
              ..[fieldName] = fieldPolicy!.merge!(
                existingFieldData,
                fieldData,
                FieldFunctionOptions(
                  field: field,
                  config: config,
                ),
              );
          }
          return data..[fieldName] = fieldData;
        } on PartialDataException catch (e) {
          throw PartialDataException(path: [inputKey, ...e.path]);
        }
      })
    };

    if (dataId != null) existingNormalizedData = config.read(dataId);

    final mergedData = deepMerge(
      Map.from(existingNormalizedData as Map<dynamic, dynamic>? ?? {}),
      dataToMerge,
    );

    if (!root && dataId != null) {
      write(dataId, mergedData);
      return {config.referenceKey: dataId};
    } else {
      return mergedData;
    }
  }

  throw Exception(
    'There are sub-selections on this node, but the data is not null, an Array, or a Map',
  );
}
