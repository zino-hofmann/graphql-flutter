import 'package:graphql_normalize/src/policies/type_policy.dart';
import 'package:graphql_normalize/src/utils/resolve_root_typename.dart';

import 'constants.dart';

/// Returns a set of dataIds that can be reached by any root query.
Set<String> reachableIds(
  Map<String, dynamic>? Function(String dataId) read, [
  Map<String, TypePolicy> typePolicies = const {},
  String referenceKey = kDefaultReferenceKey,
]) =>
    defaultRootTypenames.keys
        .map(
      (type) => typenameForOperationType(
        type,
        typePolicies,
      ),
    )
        .fold(
      {},
      (ids, rootTypename) => ids
        ..add(rootTypename)
        ..addAll(
          _idsInObject(
            read(rootTypename),
            read,
            referenceKey,
            {},
          ),
        ),
    );

/// Returns a set of all IDs reachable from the given data ID.
///
/// Includes the given [dataId] itself.
Set<String> reachableIdsFromDataId(
  String dataId,
  Map<String, dynamic>? Function(String dataId) read, [
  String referenceKey = kDefaultReferenceKey,
]) =>
    _idsInObject(read(dataId), read, referenceKey, {})..add(dataId);

/// Recursively finds reachable IDs in [object]
Set<String> _idsInObject(
  Object? object,
  Map<String, dynamic>? Function(String dataId) read,
  String referenceKey,
  Set<String> visited,
) {
  if (object is Map) {
    if (object.containsKey(referenceKey)) {
      if (visited.contains(object[referenceKey])) return {};
      return {object[referenceKey] as String}..addAll(
          _idsInObject(
            read(object[referenceKey] as String),
            read,
            referenceKey,
            visited..add(object[referenceKey] as String),
          ),
        );
    }
    return object.values.fold(
      {},
      (ids, element) => ids
        ..addAll(
          _idsInObject(
            element,
            read,
            referenceKey,
            visited,
          ),
        ),
    );
  } else if (object is List) {
    return object.fold(
      {},
      (ids, element) => ids
        ..addAll(
          _idsInObject(
            element,
            read,
            referenceKey,
            visited,
          ),
        ),
    );
  }
  return {};
}
