import 'dart:collection';
import 'dart:convert';

import 'package:graphql_normalize/utils.dart';

import '../policies/type_policy.dart';
import './exceptions.dart';

typedef DataIdResolver = String? Function(Map<String, dynamic> object);

/// Returns a unique ID to use to reference this normalized object.
///
/// First checks if a [TypePolicy] exists for the given type. Next,
/// calls the [dataIdFromObject] function if one is specified.
/// If none is provided, falls back to the 'id' or '_id' field, respectively.
///
/// Returns [null] if this type should not be normalized.
String? resolveDataId({
  required Map<String, dynamic> data,
  required Map<String, TypePolicy> typePolicies,
  DataIdResolver? dataIdFromObject,
}) {
  final typename = data['__typename'] as String?;
  if (typename == null) return null;

  final typePolicy = typePolicies[typename];
  final keyFields = typePolicy?.keyFields;
  if (keyFields != null) {
    if (keyFields.isEmpty) return null;

    try {
      final fields = keyFieldsWithArgs(keyFields, data);
      return '$typename:${json.encode(fields)}';
    } on MissingKeyFieldException {
      return null;
    }
  }

  if (dataIdFromObject != null) return dataIdFromObject(data);

  if (allRootTypenames(typePolicies).contains(typename)) {
    return typename;
  }

  final id = data['id'] ?? data['_id'];
  return id == null ? null : '$typename:$id';
}

SplayTreeMap<String, dynamic> keyFieldsWithArgs(
  Map<String, dynamic> keyFields,
  Map data,
) =>
    keyFields.entries.fold(
      SplayTreeMap(),
      (fields, entry) {
        final key = entry.key;
        final value = entry.value;
        final dataChild = data[key];
        if (value is Map && dataChild is Map?) {
          return fields
            ..[entry.key] = keyFieldsWithArgs(
              Map<String, dynamic>.from(value),
              dataChild ?? {},
            );
        } else if (entry.value == true) {
          if (!data.containsKey(entry.key)) throw MissingKeyFieldException();
          return fields..[entry.key] = data[entry.key];
        }
        return fields;
      },
    );
