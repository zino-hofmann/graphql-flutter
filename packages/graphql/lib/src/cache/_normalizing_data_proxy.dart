import 'package:graphql/src/cache/fragment.dart';
import 'package:graphql/src/exceptions/exceptions_next.dart';
import "package:meta/meta.dart";

import 'package:gql_exec/gql_exec.dart' show Request;
import 'package:normalize/normalize.dart';

import './data_proxy.dart';
import '../utilities/helpers.dart';

typedef DataIdResolver = String? Function(Map<String, Object?> object);

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
      normalizeOperation(
        // provided from cache
        write: (dataId, value) => writeNormalized(dataId, value),
        read: (dataId) => readNormalized(dataId),
        typePolicies: typePolicies,
        dataIdFromObject: dataIdFromObject,
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
      normalizeFragment(
        // provided from cache
        write: (dataId, value) => writeNormalized(dataId, value),
        read: (dataId) => readNormalized(dataId),
        typePolicies: typePolicies,
        dataIdFromObject: dataIdFromObject,
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
