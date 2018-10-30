import 'dart:collection';
import 'package:meta/meta.dart';
import 'package:graphql_flutter/src/cache/cache.dart';
import 'package:graphql_flutter/src/cache/normalized_in_memory.dart';

class OptimisticPatch extends Object {
  String id;
  HashMap<String, dynamic> data;
  OptimisticPatch(this.id, this.data);
}

class OptimisticProxy implements Cache {
  OptimisticCache cache;
  HashMap<String, dynamic> data = HashMap<String, dynamic>();
  OptimisticProxy(this.cache);

  @override
  dynamic read(String key) {
    if (data.containsKey(key)) {
      return cache.denormalize(data[key]);
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
    print(optimisticPatches);
    for (OptimisticPatch patch in optimisticPatches) {
      if (patch.data.containsKey(key)) {
        return denormalize(patch.data[key]);
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
    optimisticPatches.insert(0, OptimisticPatch(addId, patch.data));
  }

  void removeOptimisticPatch(String removeId) {
    optimisticPatches.removeWhere(
      (OptimisticPatch patch) => patch.id != removeId,
    );
  }
}
