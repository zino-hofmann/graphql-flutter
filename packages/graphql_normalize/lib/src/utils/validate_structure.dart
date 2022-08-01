import 'package:gql/ast.dart';
import 'package:graphql_normalize/src/denormalize_node.dart';

import 'package:graphql_normalize/src/denormalize_operation.dart';
import 'package:graphql_normalize/src/denormalize_fragment.dart';
import 'package:graphql_normalize/src/utils/constants.dart';
import 'package:graphql_normalize/src/utils/exceptions.dart';
import 'package:graphql_normalize/utils.dart';

Map<String, dynamic>? _unsupportedRead(String _key) {
  throw UnsupportedError('Should never read while validating');
}

String? _stubDataIdFromObject(Map<String, dynamic> _data) => null;

/// Validates the structure of [data] against the operation [operationName] in [document].
///
/// Throws a [PartialDataException] if the data is invalid,
/// unless `handleException=true`, in which case it returns `false`.
///
/// Treats `null` data as invalid, thus distinguishing between _valid_ data,
/// and data which is simply _not present_ as defined by the [spec].
///
/// Calls [denormalizeOperation] internally.
///
/// [spec]: https://spec.graphql.org/June2018/#sec-Data
bool validateOperationDataStructure({
  required DocumentNode document,
  required Map<String, dynamic>? data,
  String? operationName,
  Map<String, dynamic> variables = const {},
  bool addTypename = false,
  bool handleException = false,
}) {
  return _validateSelectionSet(
    document: document,
    getSelectionSet: ({required document, required fragmentMap}) =>
        getOperationDefinition(document, operationName).selectionSet,
    data: data,
    variables: variables,
    addTypename: addTypename,
    handleException: handleException,
  );
}

/// Validates the structure of [data] against the fragment [fragmentName] in [document].
///
/// Throws a [PartialDataException] if the data is invalid,
/// unless `handleException=true`, in which case it returns `false`.
///
/// **NOTE:** while `null` data is a theoretically acceptable value for any fragment in isolation,
/// we treat it as invalid here, maintaining consistency with [denormalizeOperation].
///
/// Calls [denormalizeFragment] internally.
bool validateFragmentDataStructure({
  required DocumentNode document,
  required Map<String, dynamic>? data,
  String? fragmentName,
  Map<String, dynamic> variables = const {},
  bool addTypename = false,
  bool handleException = false,
}) {
  return _validateSelectionSet(
    document: document,
    getSelectionSet: ({required document, required fragmentMap}) {
      return findFragmentInFragmentMap(
        fragmentMap: fragmentMap,
        fragmentName: fragmentName,
      ).selectionSet;
    },
    data: data,
    variables: variables,
    addTypename: addTypename,
    handleException: handleException,
  );
}

typedef SelectionSetFinder = SelectionSetNode Function({
  required DocumentNode document,
  required Map<String, FragmentDefinitionNode> fragmentMap,
});

bool _validateSelectionSet({
  required DocumentNode document,
  required SelectionSetFinder getSelectionSet,
  required Map<String, dynamic>? data,
  required Map<String, dynamic> variables,
  required bool addTypename,
  required bool handleException,
}) {
  if (data == null) {
    if (handleException) {
      return false;
    }
    throw PartialDataException(path: []);
  }

  if (addTypename) {
    document = transform(
      document,
      [AddTypenameVisitor()],
    );
  }
  final fragmentMap = getFragmentMap(document);
  final config = NormalizationConfig(
    read: _unsupportedRead,
    variables: variables,
    typePolicies: const {},
    referenceKey: kDefaultReferenceKey,
    fragmentMap: fragmentMap,
    dataIdFromObject: _stubDataIdFromObject,
    addTypename: addTypename,
    allowPartialData: false,
    possibleTypes: const {},
  );
  try {
    return denormalizeNode(
          selectionSet: getSelectionSet(
            document: document,
            fragmentMap: fragmentMap,
          ),
          dataForNode: data,
          config: config,
        ) !=
        null;
  } on PartialDataException {
    if (handleException) {
      return false;
    }
    rethrow;
  }
}
