import 'package:gql/ast.dart';
import 'package:graphql_normalize/src/utils/constants.dart';

import 'package:graphql_normalize/src/utils/resolve_data_id.dart';
import 'package:graphql_normalize/src/policies/type_policy.dart';
import 'package:graphql_normalize/src/utils/add_typename_visitor.dart';
import 'package:graphql_normalize/src/normalize_node.dart';
import 'package:graphql_normalize/src/config/normalization_config.dart';
import 'package:graphql_normalize/src/utils/get_fragment_map.dart';

/// Normalizes data for a given fragment
///
/// Pass in [read] and [write] functions to read and write the result to the
/// denormalized map.
///
/// An [idFields] Map must be provided that includes all identifying data, per
/// any pertinent [TypePolicy] or [dataIdFromObject] funciton. If entities of
/// this type are simply identified by their [__typename] & [id] fields, you
/// can simply provide a map with just the [id] field (i.e. `{ "id": "1234" }`).
///
/// IDs are generated for each entity based on the following:
/// 1. If no __typename field exists, the entity will not be normalized.
/// 2. If a [TypePolicy] is provided for the given type, it's [TypePolicy.keyFields] are used.
/// 3. If a [dataIdFromObject] funciton is provided, the result is used.
/// 4. The 'id' or '_id' field (respectively) are used.
///
/// The [referenceKey] is used to reference the ID of a normalized object. It
/// should begin with '$' since a graphl response object key cannot begin with
/// that symbol. If none is provided, we will use '$ref' by default.
void normalizeFragment({
  required void Function(String dataId, Map<String, dynamic>? value) write,
  required Map<String, dynamic>? Function(String dataId) read,
  required DocumentNode document,
  required Map<String, dynamic> idFields,
  required Map<String, dynamic> data,
  String? fragmentName,
  Map<String, dynamic> variables = const {},
  Map<String, TypePolicy> typePolicies = const {},
  DataIdResolver? dataIdFromObject,
  bool addTypename = false,
  String referenceKey = kDefaultReferenceKey,
  bool acceptPartialData = true,
  Map<String, Set<String>> possibleTypes = const {},
}) {
  // Always add typenames to ensure data is stored with typename
  document = transform(
    document,
    [AddTypenameVisitor()],
  );

  final fragmentMap = getFragmentMap(document);

  if (fragmentMap.length > 1 && fragmentName == null) {
    throw Exception('Multiple fragments defined, but no fragmentName provided');
  }

  if (fragmentName != null && fragmentMap[fragmentName] == null) {
    throw Exception('Fragment "$fragmentName" not found');
  }

  final fragmentDefinition = fragmentName != null
      ? fragmentMap[fragmentName]!
      : fragmentMap.values.first;

  final dataForFragment = {
    ...data,
    '__typename': fragmentDefinition.typeCondition.on.name.value,
    ...idFields,
  };

  final config = NormalizationConfig(
    read: read,
    variables: variables,
    typePolicies: typePolicies,
    referenceKey: referenceKey,
    fragmentMap: fragmentMap,
    addTypename: addTypename,
    dataIdFromObject: dataIdFromObject,
    allowPartialData: acceptPartialData,
    possibleTypes: possibleTypes,
  );

  final dataId = resolveDataId(
    data: dataForFragment,
    typePolicies: typePolicies,
    dataIdFromObject: dataIdFromObject,
  );

  if (dataId == null) {
    throw Exception(
      'Unable to resolve data ID for type ${fragmentDefinition.typeCondition.on.name.value}. Please ensure that you are passing the correct ID fields',
    );
  }

  write(
    dataId,
    normalizeNode(
      selectionSet: fragmentDefinition.selectionSet,
      dataForNode: dataForFragment,
      existingNormalizedData: config.read(dataId),
      config: config,
      write: write,
      root: true,
    ) as Map<String, dynamic>?,
  );
}
