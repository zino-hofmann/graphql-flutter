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
      return read(node[1] as String);
    }

    return null;
  }

  @override
  dynamic read(String key) {
    if (data.containsKey(key)) {
      final Object value = data[key];
      return value is Map<String, Object>
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

typedef CacheTransform = Cache Function(Cache proxy);

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
    Object value = super.read(key);
    for (OptimisticPatch patch in optimisticPatches) {
      if (patch.data.containsKey(key)) {
        final Object patchData = patch.data[key];
        if (value is Map<String, Object> && patchData is Map<String, Object>) {
          value = patchData
            ..addAll(
                value is LazyMap ? value.data : value as Map<String, Object>);
        } else {
          // Overwrite if not mergable
          value = patchData;
        }
      }
    }
    return value is Map<String, Object> ? lazilyDenormalized(value) : value;
  }

  OptimisticProxy get _proxy => OptimisticProxy(this);

  void addOptimisiticPatch(
    String addId,
    CacheTransform transform,
  ) {
    final OptimisticProxy patch = transform(_proxy) as OptimisticProxy;
    optimisticPatches.add(OptimisticPatch(addId, patch.data));
  }

  void removeOptimisticPatch(String removeId) {
    optimisticPatches.removeWhere(
      (OptimisticPatch patch) => patch.id == removeId,
    );
  }
}
