import 'dart:collection';
import 'dart:convert';

import 'package:graphql/src/cache/fragment.dart';
import 'package:graphql/src/exceptions/exceptions_next.dart';
import "package:meta/meta.dart";

import 'package:gql_exec/gql_exec.dart' show Request;
import 'package:normalize/normalize.dart';

import './data_proxy.dart';
import '../utilities/helpers.dart';

typedef DataIdResolver = String? Function(Map<String, Object?> object);
typedef _NormalizeDataIdResolver = String? Function(
    Map<String, dynamic> object);

class _MissingKeyFieldException implements Exception {
  const _MissingKeyFieldException();
}

class _VisitedPair {
  const _VisitedPair(this.left, this.right);

  final Object left;
  final Object right;

  @override
  bool operator ==(Object other) =>
      other is _VisitedPair &&
      identical(left, other.left) &&
      identical(right, other.right);

  @override
  int get hashCode => Object.hash(
        identityHashCode(left),
        identityHashCode(right),
      );
}

class _WriteNormalizationConfig {
  const _WriteNormalizationConfig({
    required this.typePolicies,
    required this.dataIdFromObject,
  });

  final Map<String, TypePolicy> typePolicies;
  final _NormalizeDataIdResolver dataIdFromObject;
}

/// Implements the core (de)normalization api leveraged by the cache and proxy,
///
/// [readNormalized] and [writeNormalized] must still be supplied by the implementing class
abstract class NormalizingDataProxy extends GraphQLDataProxy {
  /// `typePolicies` to pass down to `normalize`
  Map<String, TypePolicy> get typePolicies;

  /// `possibleTypes` to pass down to [normalize]
  Map<String, Set<String>> get possibleTypes;

  /// Optional `dataIdFromObject` function to pass through to [normalize]
  DataIdResolver? get dataIdFromObject;

  /// Whether to add `__typename` automatically.
  ///
  /// This is `false` by default because [gql] automatically adds `__typename` already.
  ///
  /// If [addTypename] is true, it is important for the client
  /// to add `__typename` to each request automatically as well.
  /// Otherwise, a round trip to the cache will nullify results unless
  /// [returnPartialData] is `true`
  bool addTypename = false;

  /// Used for testing.
  ///
  /// Passed through to normalize. When [denormalizeOperation] isn't passed [returnPartialData],
  /// It will simply return `null` if any part of the query can't be constructed.
  ///
  /// **NOTE**: This is not exposed as a configuration for a reason.
  /// If enabled, it would be easy to eagerly return an unexpected partial result from the cache,
  /// resulting in mangled and hard-to-reason-about app state.
  @protected
  bool get returnPartialData => false;

  /// Whether it is permissible to write partial data to the this proxy.
  /// Determined by [PartialDataCachePolicy]
  ///
  /// Passed through to normalize. When [normalizeOperation] isn't passed [acceptPartialData],
  /// It will set missing fields to `null` if any part of a structurally valid query result is missing.
  bool get acceptPartialData;

  /// Flag used to request a (re)broadcast from the [QueryManager].
  ///
  /// This is set on every [writeQuery] and [writeFragment] by default.
  @protected
  @visibleForTesting
  bool broadcastRequested = false;

  /// Read normaized data from the cache
  ///
  /// Called from [readQuery] and [readFragment], which handle denormalization.
  ///
  /// The key differentiating factor for an implementing `cache` or `proxy`
  /// is usually how they handle [optimistic] reads.
  @protected
  Map<String, dynamic>? readNormalized(String rootId, {bool optimistic});

  /// Write normalized data into the cache.
  ///
  /// Called from [writeQuery] and [writeFragment].
  /// Implementors are expected to handle deep merging results themselves
  @protected
  void writeNormalized(String dataId, Map<String, dynamic>? value);

  /// Variable sanitizer for referencing custom scalar types in cache keys.
  @protected
  late SanitizeVariables sanitizeVariables;

  _WriteNormalizationConfig _writeNormalizationConfig() {
    final seenByDataId = <String, Map<String, Object?>>{};

    return _WriteNormalizationConfig(
      typePolicies: _typePoliciesWithoutKeyFields,
      dataIdFromObject: (object) {
        final dataId =
            _resolveDataIdForWrite(Map<String, Object?>.from(object));
        if (dataId == null) {
          return null;
        }

        final previousObject = seenByDataId[dataId];
        if (previousObject == null) {
          seenByDataId[dataId] = Map<String, Object?>.from(object);
          return dataId;
        }

        if (_hasConflictingValues(previousObject, object)) {
          return null;
        }

        seenByDataId[dataId] =
            _mergeSeenObject(previousObject, Map<String, Object?>.from(object));
        return dataId;
      },
    );
  }

  Map<String, TypePolicy> get _typePoliciesWithoutKeyFields {
    var hasKeyFields = false;
    final strippedTypePolicies = <String, TypePolicy>{};

    for (final entry in typePolicies.entries) {
      final typePolicy = entry.value;
      if (typePolicy.keyFields != null) {
        hasKeyFields = true;
        strippedTypePolicies[entry.key] = TypePolicy(
          queryType: typePolicy.queryType,
          mutationType: typePolicy.mutationType,
          subscriptionType: typePolicy.subscriptionType,
          fields: typePolicy.fields,
        );
      } else {
        strippedTypePolicies[entry.key] = typePolicy;
      }
    }

    return hasKeyFields ? strippedTypePolicies : typePolicies;
  }

  String? _resolveDataIdForWrite(Map<String, Object?> object) {
    final typename = object['__typename'];
    if (typename is! String) {
      return null;
    }

    final typePolicy = typePolicies[typename];
    final keyFields = typePolicy?.keyFields;
    if (keyFields != null) {
      if (keyFields.isEmpty) {
        return null;
      }

      try {
        return '$typename:${json.encode(_keyFieldsWithArgs(keyFields, object))}';
      } on _MissingKeyFieldException {
        return null;
      }
    }

    final customDataId = dataIdFromObject?.call(object);
    if (customDataId != null) {
      return customDataId;
    }

    if (_allRootTypenames.contains(typename)) {
      return typename;
    }

    final id = object['id'] ?? object['_id'];
    return id == null ? null : '$typename:$id';
  }

  Set<String> get _allRootTypenames => {
        _typenameForRoot(
          (typePolicy) => typePolicy.queryType,
          'Query',
        ),
        _typenameForRoot(
          (typePolicy) => typePolicy.mutationType,
          'Mutation',
        ),
        _typenameForRoot(
          (typePolicy) => typePolicy.subscriptionType,
          'Subscription',
        ),
      };

  String _typenameForRoot(
    bool Function(TypePolicy typePolicy) matches,
    String fallback,
  ) {
    for (final entry in typePolicies.entries) {
      if (matches(entry.value)) {
        return entry.key;
      }
    }
    return fallback;
  }

  SplayTreeMap<String, dynamic> _keyFieldsWithArgs(
    Map<String, dynamic> keyFields,
    Map<String, Object?> data,
  ) {
    final fields = SplayTreeMap<String, dynamic>();

    for (final entry in keyFields.entries) {
      if (entry.value is Map<String, dynamic>) {
        final nestedData = data[entry.key];
        fields[entry.key] = _keyFieldsWithArgs(
          entry.value as Map<String, dynamic>,
          nestedData is Map
              ? Map<String, Object?>.from(nestedData.cast<String, Object?>())
              : const {},
        );
      } else if (entry.value == true) {
        if (!data.containsKey(entry.key)) {
          throw const _MissingKeyFieldException();
        }
        fields[entry.key] = data[entry.key];
      }
    }

    return fields;
  }

  bool _hasConflictingValues(
    Object? previousValue,
    Object? currentValue, [
    Set<_VisitedPair>? visited,
  ]) {
    if (identical(previousValue, currentValue) ||
        previousValue == currentValue) {
      return false;
    }

    visited ??= <_VisitedPair>{};

    if (previousValue is Map && currentValue is Map) {
      final pair = _VisitedPair(previousValue, currentValue);
      if (!visited.add(pair)) {
        return false;
      }

      for (final entry in currentValue.entries) {
        if (!previousValue.containsKey(entry.key)) {
          continue;
        }
        if (_hasConflictingValues(
          previousValue[entry.key],
          entry.value,
          visited,
        )) {
          return true;
        }
      }

      return false;
    }

    if (previousValue is List && currentValue is List) {
      final pair = _VisitedPair(previousValue, currentValue);
      if (!visited.add(pair)) {
        return false;
      }

      if (previousValue.length != currentValue.length) {
        return true;
      }

      for (var index = 0; index < currentValue.length; index++) {
        if (_hasConflictingValues(
          previousValue[index],
          currentValue[index],
          visited,
        )) {
          return true;
        }
      }

      return false;
    }

    return previousValue is Map ||
        currentValue is Map ||
        previousValue is List ||
        currentValue is List ||
        previousValue != currentValue;
  }

  Map<String, Object?> _mergeSeenObject(
    Map<String, Object?> previousObject,
    Map<String, Object?> currentObject, [
    Set<_VisitedPair>? visited,
  ]) {
    visited ??= <_VisitedPair>{};

    final pair = _VisitedPair(previousObject, currentObject);
    if (!visited.add(pair)) {
      return previousObject;
    }

    final mergedObject = Map<String, Object?>.from(previousObject);
    for (final entry in currentObject.entries) {
      mergedObject[entry.key] = _mergeSeenValue(
        mergedObject[entry.key],
        entry.value,
        visited,
      );
    }

    return mergedObject;
  }

  Object? _mergeSeenValue(
    Object? previousValue,
    Object? currentValue, [
    Set<_VisitedPair>? visited,
  ]) {
    visited ??= <_VisitedPair>{};

    if (previousValue is Map && currentValue is Map) {
      return _mergeSeenObject(
        Map<String, Object?>.from(previousValue.cast<String, Object?>()),
        Map<String, Object?>.from(currentValue.cast<String, Object?>()),
        visited,
      );
    }

    if (previousValue is List && currentValue is List) {
      final pair = _VisitedPair(previousValue, currentValue);
      if (!visited.add(pair)) {
        return previousValue;
      }

      if (previousValue.length != currentValue.length) {
        return currentValue;
      }

      return List<Object?>.generate(
        currentValue.length,
        (index) => _mergeSeenValue(
          previousValue[index],
          currentValue[index],
          visited,
        ),
      );
    }

    return currentValue;
  }

  Map<String, dynamic>? readQuery(
    Request request, {
    bool optimistic = true,
  }) =>
      denormalizeOperation(
        // provided from cache
        read: (dataId) => readNormalized(dataId, optimistic: optimistic),
        typePolicies: typePolicies,
        dataIdFromObject: dataIdFromObject,
        returnPartialData: returnPartialData,
        addTypename: addTypename,
        // if there is partial data, we cannot read and return null
        handleException: true,
        // provided from request
        document: request.operation.document,
        operationName: request.operation.operationName,
        variables: sanitizeVariables(request.variables)!,
        possibleTypes: possibleTypes,
      );

  Map<String, dynamic>? readFragment(
    FragmentRequest fragmentRequest, {
    bool optimistic = true,
  }) =>
      denormalizeFragment(
        // provided from cache
        read: (dataId) => readNormalized(dataId, optimistic: optimistic),
        typePolicies: typePolicies,
        dataIdFromObject: dataIdFromObject,
        returnPartialData: returnPartialData,
        addTypename: addTypename,
        // if there is partial data, we cannot read and return null
        handleException: true,
        // provided from request
        document: fragmentRequest.fragment.document,
        idFields: fragmentRequest.idFields,
        fragmentName: fragmentRequest.fragment.fragmentName,
        variables: sanitizeVariables(fragmentRequest.variables)!,
        possibleTypes: possibleTypes,
      );

  void writeQuery(
    Request request, {
    required Map<String, dynamic> data,
    bool? broadcast = true,
  }) {
    try {
      final config = _writeNormalizationConfig();
      normalizeOperation(
        // provided from cache
        write: (dataId, value) => writeNormalized(dataId, value),
        read: (dataId) => readNormalized(dataId),
        typePolicies: config.typePolicies,
        dataIdFromObject: config.dataIdFromObject,
        acceptPartialData: acceptPartialData,
        addTypename: addTypename,
        // provided from request
        document: request.operation.document,
        operationName: request.operation.operationName,
        variables: sanitizeVariables(request.variables)!,
        // data
        data: data,
        possibleTypes: possibleTypes,
      );
      if (broadcast ?? true) {
        broadcastRequested = true;
      }
    } on PartialDataException catch (e, stackTrace) {
      if (request.validatesStructureOf(data)) {
        throw CacheMisconfigurationException(
          e,
          stackTrace,
          request: request,
          data: data,
        );
      }
      rethrow;
    }
  }

  void writeFragment(
    FragmentRequest request, {
    required Map<String, dynamic> data,
    bool? broadcast = true,
  }) {
    try {
      final config = _writeNormalizationConfig();
      normalizeFragment(
        // provided from cache
        write: (dataId, value) => writeNormalized(dataId, value),
        read: (dataId) => readNormalized(dataId),
        typePolicies: config.typePolicies,
        dataIdFromObject: config.dataIdFromObject,
        acceptPartialData: acceptPartialData,
        addTypename: addTypename,
        // provided from request
        document: request.fragment.document,
        idFields: request.idFields,
        fragmentName: request.fragment.fragmentName,
        variables: sanitizeVariables(request.variables)!,
        // data
        data: data,
        possibleTypes: possibleTypes,
      );
      if (broadcast ?? true) {
        broadcastRequested = true;
      }
    } on PartialDataException catch (e, stackTrace) {
      if (request.validatesStructureOf(data)) {
        throw CacheMisconfigurationException(
          e,
          stackTrace,
          fragmentRequest: request,
          data: data,
        );
      }
      rethrow;
    }
  }
}
