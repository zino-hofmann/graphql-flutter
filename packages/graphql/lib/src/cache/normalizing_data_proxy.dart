import "package:meta/meta.dart";

import 'package:gql_exec/gql_exec.dart' show Request;
import 'package:gql/ast.dart' show DocumentNode;

import 'package:normalize/normalize.dart';

import './data_proxy.dart';

typedef DataIdResolver = String Function(Map<String, Object> object);

/// Implements the core normalization api leveraged by the cache and proxy
///
/// `read` and `write` must still be supplied by the implementing class
abstract class NormalizingDataProxy extends GraphQLDataProxy {
  Map<String, TypePolicy> typePolicies;
  bool addTypename;

  DataIdResolver dataIdFromObject;

  dynamic read(String rootId, {bool optimistic});

  void write(String dataId, dynamic value);

  Map<String, dynamic> readQuery(
    Request request, {
    bool optimistic = true,
  }) =>
      denormalize(
        reader: (dataId) => read(dataId, optimistic: optimistic),
        query: request.operation.document,
        operationName: request.operation.operationName,
        variables: request.variables,
        typePolicies: typePolicies,
        addTypename: addTypename,
      );

  Map<String, dynamic> readFragment({
    @required DocumentNode fragment,
    @required Map<String, dynamic> idFields,
    String fragmentName,
    Map<String, dynamic> variables,
    bool optimistic = true,
  }) =>
      denormalizeFragment(
        reader: (dataId) => read(dataId, optimistic: optimistic),
        fragment: fragment,
        idFields: idFields,
        fragmentName: fragmentName,
        variables: variables,
        typePolicies: typePolicies,
        addTypename: addTypename,
        dataIdFromObject: dataIdFromObject,
      );

  /// [normalize] the given `data` into the cache using graphql metadata from `request`
  void writeQuery(
    Request request,
    Map<String, dynamic> data, {
    String queryId,
  }) =>
      normalize(
        writer: (dataId, value) => write(dataId, value),
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
        writer: (dataId, value) => write(dataId, value),
        fragment: fragment,
        idFields: idFields,
        data: data,
        fragmentName: fragmentName,
        variables: variables,
        typePolicies: typePolicies,
        dataIdFromObject: dataIdFromObject,
      );
}
