import 'dart:collection';
import 'package:meta/meta.dart';
import 'package:graphql_flutter/src/cache/cache.dart';
import 'package:graphql_flutter/src/cache/normalized_in_memory.dart';

import './lazy_cache_map.dart';

class OptimisticPatch extends Object {
  OptimisticPatch(this.id, this.data);
  String id;
  HashMap<String, dynamic> data;
}

class OptimisticProxy implements Cache {
  OptimisticProxy(this.cache);
  OptimisticCache cache;
  HashMap<String, dynamic> data = HashMap<String, dynamic>();

  Object _dereference(Object node) {
    if (node is List && node.length == 2 && node[0] == cache.prefix) {
      return read(node[1]);
    }

    return null;
  }

  @override
  dynamic read(String key) {
    if (data.containsKey(key)) {
      final Object value = data[key];
      return value is Map
          ? LazyMap(data: value, dereference: _dereference)
          : value;
    }
    return cache.read(key);
  }

  @override
  void write(String key, dynamic value) {
    cache.writeInto(key, value, data);
  }

  // TODO should persistence be a seperate concern from caching
  @override
  void save() {}
  @override
  void restore() {}
  @override
  void reset() {}
}

typedef Cache CacheTransform(Cache proxy);

class OptimisticCache extends NormalizedInMemoryCache {
  @protected
  List<OptimisticPatch> optimisticPatches = <OptimisticPatch>[];

  OptimisticCache({
    @required DataIdFromObject dataIdFromObject,
    String prefix = '@cache/reference',
  }) : super(dataIdFromObject: dataIdFromObject, prefix: prefix);

  /// Reads and dereferences an entity from the first valid optimistic layer,
  /// defaulting to the base internal HashMap.
  @override
  dynamic read(String key) {
    for (OptimisticPatch patch in optimisticPatches.reversed) {
      if (patch.data.containsKey(key)) {
        return lazilyDenormalized(patch.data[key]);
      }
    }
    return super.read(key);
  }

  OptimisticProxy get _proxy => OptimisticProxy(this);

  void addOptimisiticPatch(
    String addId,
    CacheTransform transform,
  ) {
    final OptimisticProxy patch = transform(_proxy);
    optimisticPatches.add(OptimisticPatch(addId, patch.data));
  }

  void removeOptimisticPatch(String removeId) {
    optimisticPatches.removeWhere(
      (OptimisticPatch patch) => patch.id == removeId,
    );
  }
}
