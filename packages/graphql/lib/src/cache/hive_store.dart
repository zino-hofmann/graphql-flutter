import 'package:meta/meta.dart';

import 'package:hive/hive.dart';

import './store.dart';

@immutable
class HiveStore extends Store {
  @protected
  final Box box;

  /// Creates a HiveStore inititalized with [box],
  /// which defaults to `Hive.box('defaultGraphqlStore')`
  HiveStore([
    Box box,
  ]) : box = box ?? Hive.box('defaultGraphqlStore');

  @override
  Map<String, dynamic> get(String dataId) {
    final result = box.get(dataId);
    if (result == null) return null;
    return Map.from(result);
  }

  @override
  void put(String dataId, Map<String, dynamic> value) {
    box.put(dataId, value);
  }

  @override
  void putAll(Map<String, Map<String, dynamic>> data) {
    box.putAll(data);
  }

  @override
  void delete(String dataId) {
    box.delete(dataId);
  }

  @override
  Map<String, Map<String, dynamic>> toMap() => Map.unmodifiable(box.toMap());

  void reset() => box.clear();
}
