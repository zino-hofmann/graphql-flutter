import "package:meta/meta.dart";

import 'package:gql_exec/gql_exec.dart' show Request;
import 'package:gql/ast.dart' show DocumentNode;

import './data_proxy.dart';

abstract class Cache {
  dynamic read(String key) {}

  void write(
    String key,
    dynamic value,
  ) {}

  Future<void> save() async {}

  void restore() {}

  void reset() {}
}

class ReadRequest extends Request {
  /// The root query id to read from the store
  ///
  /// defaults to the root query of the graphql schema
  String rootId;

  /// Whether to include optimistic results
  bool optimistic;

  ///  Previous result of this query, if any
  // dynamic previousResult;

}

class WriteRequest extends Request {
  /// The data id to read from the store
  String dataId;

  /// Whether to write as an optimistic patch
  bool optimistic;

  /// Result to write
  dynamic result;
}

// Restore, reset, extract should be on store

abstract class GrahpQLCache extends GraphQLDataProxy {
  // required to implement
  // core API
  dynamic read(ReadRequest request);

  void write(WriteRequest request);

  ///If called with only one argument, removes the entire entity
  /// identified by dataId.
  ///
  /// If called with a [fieldName] as well, removes all
  /// fields of the identified entity whose store names match fieldName.
  bool evict(String dataId, [String fieldName]);

  // optimistic API
  void removeOptimisticPatch(String id);
}
