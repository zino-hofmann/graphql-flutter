import 'dart:core';
import 'package:quiver/core.dart' show hash3;

import 'package:meta/meta.dart';

typedef Dereference = Object Function(Object node);

enum CacheState { OPTIMISTIC }

/// A [LazyDereferencingMap] into the cache with added `cacheState` information
class LazyCacheMap extends LazyDereferencingMap {
  LazyCacheMap(
    Map<String, Object> data, {
    @required Dereference dereference,
    CacheState cacheState,
  })  : cacheState =
            cacheState ?? (data is LazyCacheMap ? data.cacheState : null),
        super(data, dereference: dereference);

  final CacheState cacheState;
  bool get isOptimistic => cacheState == CacheState.OPTIMISTIC;

  @override
  Object getValue(Object value) {
    final Object result = _dereference(value) ?? value;
    if (result is List) {
      return result.map(getValue).toList();
    }
    if (result is Map<String, Object>) {
      return LazyCacheMap(
        result,
        dereference: _dereference,
      );
    }
    return result;
  }

  int get hashCode => hash3(_data, _dereference, cacheState);

  bool operator ==(Object other) =>
      other is LazyCacheMap &&
      other._data == _data &&
      other._dereference == _dereference &&
      other.cacheState == cacheState;
}

/// Unwrap a given Object that could possibly be a lazy map
Object unwrap(Object possibleLazyMap) => possibleLazyMap is LazyDereferencingMap
    ? possibleLazyMap.data
    : possibleLazyMap;

/// Unwrap a given mpa that could possibly be a lazy map
Map<String, Object> unwrapMap(Map<String, Object> possibleLazyMap) =>
    possibleLazyMap is LazyDereferencingMap
        ? possibleLazyMap.data
        : possibleLazyMap;

/// A simple map wrapper that lazily dereferences using `dereference`
///
/// Wrapper that calls `dereference(value)` for each value before returning,
/// replacing that `value` with the result if not `null`.
@immutable
class LazyDereferencingMap implements Map<String, Object> {
  LazyDereferencingMap(
    Map<String, Object> data, {
    @required Dereference dereference,
  })  : _data = unwrap(data) as Map<String, Object>,
        _dereference = dereference;

  final Dereference _dereference;

  final Map<String, Object> _data;

  /// get the wrapped `Map` without dereferencing
  Map<String, Object> get data => _data;

  @protected
  Object getValue(Object value) {
    final Object result = _dereference(value) ?? value;
    // TODO maybe this should be encapsulated in a LazyList or something
    if (result is List) {
      return result.map(getValue).toList();
    }
    if (result is Map<String, Object>) {
      return LazyDereferencingMap(
        result,
        dereference: _dereference,
      );
    }
    return result;
  }

  @override
  Object operator [](Object key) => getValue(data[key]);

  Object get(Object key) => getValue(data[key]);

  @override
  bool containsKey(Object key) => data.containsKey(key);

  @override
  bool containsValue(Object value) => values.contains(value);

  @override
  Iterable<MapEntry<String, Object>> get entries => data.entries
      .map((MapEntry<String, Object> entry) => MapEntry<String, Object>(
            entry.key,
            getValue(entry.value),
          ));

  @override
  void forEach(void Function(String key, Object value) f) {
    void _forEachEntry(MapEntry<String, Object> entry) {
      f(entry.key, entry.value);
    }

    entries.forEach(_forEachEntry);
  }

  @override
  bool get isEmpty => data.isEmpty;

  @override
  bool get isNotEmpty => data.isNotEmpty;

  @override
  Iterable<String> get keys => data.keys;

  @override
  int get length => data.length;

  @override
  Map<K2, V2> map<K2, V2>(
      MapEntry<K2, V2> Function(String key, Object value) f) {
    MapEntry<K2, V2> _mapEntry(MapEntry<String, Object> entry) {
      return f(entry.key, entry.value);
    }

    return Map<K2, V2>.fromEntries(entries.map(_mapEntry));
  }

  @override
  Iterable<Object> get values => data.values.map(getValue);

  @override
  void operator []=(String key, Object value) {
    data[key] = unwrap(value);
  }

  @override
  void addAll(Map<String, Object> other) {
    data.addAll(unwrap(other) as Map<String, Object>);
  }

  @override
  void addEntries(Iterable<MapEntry<String, Object>> entries) {
    data.addEntries(entries);
  }

  @override
  void clear() {
    data.clear();
  }

  @override
  Object remove(Object key) => getValue(data.remove(key));

  @override
  void removeWhere(bool test(String key, Object value)) {
    data.removeWhere(test);
  }

  /// This operation is not supported by a [LazyUnmodifiableMapView].
  @override
  Object putIfAbsent(String key, Object ifAbsent()) =>
      getValue(data.putIfAbsent(key, ifAbsent));

  /// This operation is not supported by a [LazyUnmodifiableMapView].
  @override
  Object update(String key, Object update(Object value), {Object ifAbsent()}) =>
      getValue(data.update(key, update, ifAbsent: ifAbsent));

  @override
  void updateAll(Object update(String key, Object value)) {
    data.updateAll(update);
  }

  @override
  Map<K, V> cast<K, V>() {
    throw UnsupportedError('Cannot cast a lazy cache map map');
  }
}
