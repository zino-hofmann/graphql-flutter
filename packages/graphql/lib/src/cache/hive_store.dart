import 'dart:async';
import 'package:meta/meta.dart';

import 'package:hive/hive.dart';

import './store.dart';

Map<String, dynamic> _transformMap(Map<dynamic, dynamic> map) =>
    Map<String, dynamic>.from(
      {
        for (var entry in map.entries) entry.key: _transformAny(entry.value),
      },
    );

dynamic _transformAny(dynamic object) {
  if (object is Map) {
    return _transformMap(object);
  }
  if (object is List) {
    return _transformList(object);
  }
  return object;
}

List<dynamic> _transformList(List<dynamic> list) => List<dynamic>.from(
      [
        for (var element in list) _transformAny(element),
      ],
    );

@immutable
class HiveStore extends Store {
  /// Default box name for the `graphql/client.dart` cache store (`graphqlClientStore`)
  static const defaultBoxName = 'graphqlClientStore';

  /// Opens a box. Convenience pass through to [Hive.openBox].
  ///
  /// If the box is already open, the instance is returned and all provided parameters are being ignored.
  static Future<Box<Map<dynamic, dynamic>?>> openBox(String boxName,
      {String? path}) async {
    return await Hive.openBox<Map<dynamic, dynamic>?>(boxName, path: path);
  }

  /// Convenience factory for `HiveStore(await openBox(boxName ?? 'graphqlClientStore', path: path))`
  ///
  /// [boxName]  defaults to [defaultBoxName], [path] is optional.
  /// For full configuration of a [Box] use [HiveStore()] in tandem with [openBox] / [Hive.openBox]
  static Future<HiveStore> open({
    String boxName = defaultBoxName,
    String? path,
  }) async =>
      HiveStore(await openBox(boxName, path: path));

  /// Init Hive on specific Path
  static void init({required String onPath}) => Hive.init(onPath);

  /// Direct access to the underlying [Box].
  ///
  /// **WARNING**: Directly editing the contents of the store will not automatically
  /// rebroadcast operations.
  final Box<Map<dynamic, dynamic>?> box;

  /// Creates a HiveStore initialized with the given [box], defaulting to `Hive.box(defaultBoxName)`
  ///
  /// **N.B.**: [box] must already be [opened] with either [openBox], [open], or `initHiveForFlutter` from `graphql_flutter`.
  /// This lets us decouple the async initialization logic, making store usage elsewhere much more straightforward.
  ///
  /// [opened]: https://docs.hivedb.dev/#/README?id=open-a-box
  HiveStore([Box<Map<dynamic, dynamic>?>? box])
      : this.box = box ?? Hive.box<Map<dynamic, dynamic>?>(defaultBoxName);

  @override
  Map<String, dynamic>? get(String dataId) {
    final result = box.get(dataId);
    if (result == null) return null;
    return _transformMap(result);
  }

  @override
  void put(String dataId, Map<String, dynamic>? value) {
    box.put(dataId, value);
  }

  @override
  void putAll(Map<String, Map<String, dynamic>?> data) {
    box.putAll(data);
  }

  @override
  void delete(String dataId) {
    box.delete(dataId);
  }

  @override
  Map<String, Map<String, dynamic>?> toMap() => Map.unmodifiable(box.toMap());

  Future<void> reset() => box.clear();
}
