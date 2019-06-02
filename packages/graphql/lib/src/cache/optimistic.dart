import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart';

import 'package:graphql/src/utilities/helpers.dart';
import 'package:graphql/src/cache/cache.dart';
import 'package:graphql/src/cache/normalized_in_memory.dart';
import 'package:graphql/src/cache/lazy_cache_map.dart';

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
          ? LazyCacheMap(
              value,
              dereference: _dereference,
              cacheState: CacheState.OPTIMISTIC,
            )
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
  Future<void> save() async {}
  @override
  void restore() {}
  @override
  void reset() {}
}

typedef CacheTransform = Cache Function(Cache proxy);

class OptimisticCache extends NormalizedInMemoryCache {
  OptimisticCache({
    @required DataIdFromObject dataIdFromObject,
    String prefix = '@cache/reference',
    FutureOr<String> storagePrefix,
  }) : super(
          dataIdFromObject: dataIdFromObject,
          prefix: prefix,
          storagePrefix: storagePrefix,
        );

  @protected
  List<OptimisticPatch> optimisticPatches = <OptimisticPatch>[];

  /// Reads and dereferences an entity from the first valid optimistic layer,
  /// defaulting to the base internal HashMap.
  @override
  dynamic read(String key) {
    Object value = super.read(key);
    CacheState cacheState;
    for (OptimisticPatch patch in optimisticPatches) {
      if (patch.data.containsKey(key)) {
        final Object patchData = patch.data[key];
        if (value is Map<String, Object> && patchData is Map<String, Object>) {
          value = deeplyMergeLeft([
            value as Map<String, Object>,
            patchData,
          ]);
          cacheState = CacheState.OPTIMISTIC;
        } else {
          // Overwrite if not mergable
          value = patchData;
        }
      }
    }
    return value is Map<String, Object>
        ? lazilyDenormalized(value, cacheState)
        : value;
  }

  OptimisticProxy get _proxy => OptimisticProxy(this);

  String _parentPatchId(String id) {
    final List<String> parts = id.split('.');
    if (parts.length > 1) {
      return parts.first;
    }
    return null;
  }

  bool _patchExistsFor(String id) =>
      optimisticPatches.firstWhere((OptimisticPatch patch) => patch.id == id,
          orElse: () => null) !=
      null;

  /// avoid race conditions from slow updates
  ///
  /// if a server result is returned before an optimistic update is finished,
  /// that update is discarded
  bool _safeToAdd(String id) {
    final String parentId = _parentPatchId(id);
    return parentId == null || _patchExistsFor(parentId);
  }

  /// Add a given patch using the given [transform]
  ///
  /// 1 level of hierarchical optimism is supported:
  /// * if a patch has the id `$queryId.child`, it will be removed with `$queryId`
  /// * if the update somehow fails to complete before the root response is removed,
  ///   It will still be called, but the result will not be added.
  ///
  /// This allows for multiple optimistic treatments of a query,
  /// without having to tightly couple optimistic changes
  void addOptimisiticPatch(
    String addId,
    CacheTransform transform,
  ) {
    final OptimisticProxy patch = transform(_proxy) as OptimisticProxy;
    if (_safeToAdd(addId)) {
      optimisticPatches.add(OptimisticPatch(addId, patch.data));
    }
  }

  /// Remove a given patch from the list
  ///
  /// This will also remove all "nested" patches, such as `$queryId.update`
  /// This allows for hierarchical optimism that is automatically cleaned up
  /// without having to tightly couple optimistic changes
  void removeOptimisticPatch(String removeId) {
    optimisticPatches.removeWhere(
      (OptimisticPatch patch) =>
          patch.id == removeId || _parentPatchId(patch.id) == removeId,
    );
  }
}
