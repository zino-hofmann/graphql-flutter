import 'dart:collection';

import 'package:meta/meta.dart';

// TODO decide if [Store] should have save, etc
// TODO figure out how to reference non-imported symbols
/// Raw key-value datastore API leveraged by the [Cache]
@immutable
abstract class Store {
  Map<String, dynamic>? get(String dataId);

  /// Write [value] into this store under the key [dataId]
  void put(String dataId, Map<String, dynamic>? value);

  /// [put] all entries from [data] into the store
  ///
  /// Functionally equivalent to `data.map(put);`
  void putAll(Map<String, Map<String, dynamic>> data);

  /// Delete the value of the [dataId] from the store, if preset
  void delete(String dataId);

  /// Empty the store
  void reset();

  /// Return the entire contents of the cache as [Map].
  ///
  /// NOTE: some [Store]s might return mutable objects
  /// referenced by the store itself.
  Map<String, Map<String, dynamic>> toMap();
}

/// Simplest possible [Map]-backed store
@immutable
class InMemoryStore extends Store {
  /// Normalized map that backs the store.
  /// Defaults to an empty [HashMap]
  @protected
  @visibleForTesting
  final Map<String, dynamic> data;

  /// Creates an InMemoryStore inititalized with [data],
  /// which defaults to an empty [HashMap]
  InMemoryStore([
    Map<String, dynamic>? data,
  ]) : data = data ?? HashMap<String, dynamic>();

  @override
  Map<String, dynamic>? get(String dataId) => data[dataId];

  @override
  void put(String dataId, Map<String, dynamic>? value) => data[dataId] = value;

  @override
  void putAll(Map<String, Map<String, dynamic>> entries) =>
      data.addAll(entries);

  @override
  void delete(String dataId) => data.remove(dataId);

  /// Return the  underlying [data] as an unmodifiable [Map].
  @override
  Map<String, Map<String, dynamic>> toMap() => Map.unmodifiable(data);

  void reset() => data.clear();
}
