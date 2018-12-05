import 'dart:core';
import 'dart:core';
import 'package:meta/meta.dart';

typedef Dereference = Object Function(Object node);

/// A simple immutable map that lazily dereferences from the cache
/// The only available methods are simple read-based operations,
/// such as `[]()`, `containsKey`, and `values`
/// All mutation methods are invalid:
/// * `[]=`
/// * `addAll`
/// * `addEntries`
/// * `clear`
/// * `remove`
/// * `removeWhere`
/// * `update`
/// * `updateAll`
/// * `putIfAbsent`
/// As well as `cast`
class LazyMap implements Map<String, Object> {
  LazyMap({
    @required Map<String, Object> data,
    @required Dereference dereference,
  })  : _data = data is LazyMap ? data.data : data,
        _dereference = dereference;

  Dereference _dereference;

  final Map<String, Object> _data;
  Map<String, Object> get data => _data;

  Object _getValue(Object value) {
    final Object result = _dereference(value) ?? value;
    // TODO maybe this should be encapsulated in a LazyList or something
    if (result is List) {
      return result.map(_getValue).toList();
    }
    if (result is Map<String, Object>) {
      return LazyMap(
        data: result,
        dereference: _dereference,
      );
    }
    return result;
  }

  @override
  Object operator [](Object key) {
    return _getValue(data[key]);
  }

  @override
  bool containsKey(Object key) => data.containsKey(key);

  @override
  bool containsValue(Object value) => values.contains(value);

  @override
  Iterable<MapEntry<String, Object>> get entries => data.entries
      .map((MapEntry<String, Object> entry) => MapEntry<String, Object>(
            entry.key,
            _getValue(entry.value),
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
  Iterable<Object> get values => data.values.map(_getValue);

  @override

  /// All mutation methods are invalid:
  /// * `[]=`
  /// * `addAll`
  /// * `addEntries`
  /// * `clear`
  /// * `remove`
  /// * `removeWhere`
  /// * `update`
  /// * `updateAll`
  /// * `putIfAbsent`
  /// As well as `cast`
  void noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
