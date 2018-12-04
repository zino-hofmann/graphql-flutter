import 'dart:core';
import 'package:meta/meta.dart';

typedef Dereference = Object Function(Object node);

class LazyMap {
  LazyMap({
    @required this.data,
    @required Dereference dereference,
  }) : _dereference = dereference;

  Dereference _dereference;

  final Map<String, Object> data;

  Object operator [](Object key) {
    final Object value = data[key];
    return _dereference(value) ?? value;
  }
}
