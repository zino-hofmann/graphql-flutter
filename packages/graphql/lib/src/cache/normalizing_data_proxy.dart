import "package:meta/meta.dart";

import 'package:gql_exec/gql_exec.dart' show Request;
import 'package:gql/ast.dart' show DocumentNode;

import 'package:normalize/normalize.dart';

import './data_proxy.dart';

typedef DataIdResolver = String Function(Map<String, Object> object);

/// Implements the core (de)normalization api leveraged by the cache and proxy,
///
/// [readNormalized] and [writeNormalized] must still be supplied by the implementing class
abstract class NormalizingDataProxy extends GraphQLDataProxy {
  /// `typePolicies` to pass down to `normalize`
  Map<String, TypePolicy> typePolicies;

  /// Whether to add `__typenames` automatically
  bool addTypename;

  bool get _addTypename => addTypename ?? true;

  /// Used for testing
  @protected
  bool get returnPartialData => false;

  /// Optional `dataIdFromObject` function to pass through to [normalize]
  DataIdResolver dataIdFromObject;

  /// Read normaized data from the cache
  ///
  /// Called from [readQuery] and [readFragment], which handle denormalization.
  ///
  /// The key differentiating factor for an implementing `cache` or `proxy`
  /// is usually how they handle [optimistic] reads.
  @protected
  dynamic readNormalized(String rootId, {bool optimistic});

  /// Write normalized data into the cache.
  ///
  /// Called from [writeQuery] and [writeFragment].
  /// Implementors are expected to handle deep merging results themselves
  @protected
  void writeNormalized(String dataId, dynamic value);

  Map<String, dynamic> readQuery(
    Request request, {
    bool optimistic = true,
  }) =>
      denormalize(
        reader: (dataId) => readNormalized(dataId, optimistic: optimistic),
        query: request.operation.document,
        operationName: request.operation.operationName,
        variables: request.variables,
        typePolicies: typePolicies,
        addTypename: _addTypename,
        returnPartialData: returnPartialData,
      );

  Map<String, dynamic> readFragment({
    @required DocumentNode fragment,
    @required Map<String, dynamic> idFields,
    String fragmentName,
    Map<String, dynamic> variables,
    bool optimistic = true,
  }) =>
      denormalizeFragment(
        reader: (dataId) => readNormalized(dataId, optimistic: optimistic),
        fragment: fragment,
        idFields: idFields,
        fragmentName: fragmentName,
        variables: variables,
        typePolicies: typePolicies,
        addTypename: _addTypename,
        dataIdFromObject: dataIdFromObject,
        returnPartialData: returnPartialData,
      );

  void writeQuery(
    Request request,
    Map<String, dynamic> data, {
    String queryId,
  }) =>
      normalize(
        writer: (dataId, value) => writeNormalized(dataId, value),
        query: request.operation.document,
        operationName: request.operation.operationName,
        variables: request.variables,
        data: data,
        typePolicies: typePolicies,
        dataIdFromObject: dataIdFromObject,
      );

  void writeFragment({
    @required DocumentNode fragment,
    @required Map<String, dynamic> idFields,
    @required Map<String, dynamic> data,
    String fragmentName,
    Map<String, dynamic> variables,
    String queryId,
  }) =>
      normalizeFragment(
        writer: (dataId, value) => writeNormalized(dataId, value),
        fragment: fragment,
        idFields: idFields,
        data: data,
        fragmentName: fragmentName,
        variables: variables,
        typePolicies: typePolicies,
        dataIdFromObject: dataIdFromObject,
      );
}
