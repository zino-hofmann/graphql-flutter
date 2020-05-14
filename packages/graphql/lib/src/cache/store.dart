import 'dart:collection';

import 'package:meta/meta.dart';

@immutable
abstract class Store {
  Map<String, dynamic> get(String dataId);

  void put(String dataId, Map<String, dynamic> value);

  void putAll(Map<String, Map<String, dynamic>> data);

  void delete(String dataId);

  void reset();

  Map<String, Map<String, dynamic>> toMap();
}

@immutable
class InMemoryStore extends Store {
  @protected
  final Map<String, dynamic> data;

  InMemoryStore([Map<String, dynamic> data])
      : data = data ?? HashMap<String, dynamic>();

  @override
  Map<String, dynamic> get(String dataId) => data[dataId];

  @override
  void put(String dataId, Map<String, dynamic> value) => data[dataId] = value;

  @override
  void putAll(Map<String, Map<String, dynamic>> entries) =>
      data.addAll(entries);

  @override
  void delete(String dataId) => data.remove(dataId);

  @override
  Map<String, Map<String, dynamic>> toMap() => data;

  void reset() => data.clear();
}
