import 'package:gql/ast.dart';

import 'package:graphql_normalize/src/utils/expand_fragments.dart';
import 'package:graphql_normalize/src/utils/get_fragment_map.dart';
import 'package:graphql_normalize/src/utils/get_operation_definition.dart';
import 'package:graphql_normalize/src/utils/field_key.dart';
import 'package:graphql_normalize/src/utils/resolve_root_typename.dart';
import 'package:graphql_normalize/src/policies/type_policy.dart';

/// Returns the root field names for a given operation.
List<String> operationFieldNames<TData, TVars>(
  DocumentNode document,
  String operationName,
  Map<String, dynamic> vars,
  Map<String, TypePolicy> typePolicies,
  Map<String, Set<String>> possibleTypes,
) {
  final operationDefinition = getOperationDefinition(
    document,
    operationName,
  );
  final rootTypename = resolveRootTypename(
    operationDefinition,
    typePolicies,
  );
  final fragmentMap = getFragmentMap(document);
  final fields = expandFragments(
    typename: rootTypename,
    selectionSet: operationDefinition.selectionSet,
    fragmentMap: fragmentMap,
    possibleTypes: possibleTypes,
  );
  final typePolicy = typePolicies[rootTypename];
  return fields.map((fieldNode) {
    final fieldPolicy = (typePolicy?.fields ?? const {})[fieldNode.name.value];
    return FieldKey(
      fieldNode,
      vars,
      fieldPolicy,
    ).toString();
  }).toList();
}
