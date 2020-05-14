import 'dart:collection';

import 'package:graphql/src/cache/normalizing_data_proxy.dart';
import 'package:meta/meta.dart';

import 'package:graphql/src/cache/data_proxy.dart';

import 'package:graphql/src/utilities/helpers.dart';
import 'package:graphql/src/cache/store.dart';

export './data_proxy.dart';

typedef CacheTransaction = GraphQLDataProxy Function(GraphQLDataProxy proxy);

class OptimisticPatch extends Object {
  OptimisticPatch(this.id, this.data);
  String id;
  HashMap<String, dynamic> data;
}

class OptimisticProxy extends NormalizingDataProxy {
  OptimisticProxy(this.cache);

  GraphQLCache cache;

  HashMap<String, dynamic> data = HashMap<String, dynamic>();

  @override
  dynamic read(String rootId, {bool optimistic = true}) {
    if (!optimistic) {
      return cache.read(rootId, optimistic: false);
    }
    // the cache calls `patch.data.containsKey(rootId)`,
    // so this is not an infinite loop
    return data[rootId] ?? cache.read(rootId, optimistic: true);
  }

  @override
  void write(String dataId, dynamic value) => data[dataId] = value;
}

class GraphQLCache extends NormalizingDataProxy {
  GraphQLCache({
    Store store,
    this.dataIdFromObject,
  }) : store = store ?? InMemoryStore();

  @protected
  final Store store;

  final DataIdResolver dataIdFromObject;

  @protected
  List<OptimisticPatch> optimisticPatches = <OptimisticPatch>[];

  /// Reads and dereferences an entity from the first valid optimistic layer,
  /// defaulting to the base internal HashMap.
  Object read(String rootId, {bool optimistic = true}) {
    Object value = store.get(rootId);

    if (!optimistic) {
      return value;
    }

    for (OptimisticPatch patch in optimisticPatches) {
      if (patch.data.containsKey(rootId)) {
        final Object patchData = patch.data[rootId];
        if (value is Map<String, Object> && patchData is Map<String, Object>) {
          value = deeplyMergeLeft([
            value as Map<String, Object>,
            patchData,
          ]);
        } else {
          // Overwrite if not mergable
          value = patchData;
        }
      }
    }
    return value;
  }

  void write(String dataId, dynamic value) => store.put(dataId, value);

  OptimisticProxy get _proxy => OptimisticProxy(this);

  String _parentPatchId(String id) {
    final List<String> parts = id.split('.');
    if (parts.length > 1) {
      return parts.first;
    }
    return null;
  }

  bool _patchExistsFor(String id) =>
      optimisticPatches.firstWhere(
        (OptimisticPatch patch) => patch.id == id,
        orElse: () => null,
      ) !=
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
  void recordOptimisticTransaction(
    CacheTransaction transaction,
    String addId,
  ) {
    final OptimisticProxy patch = transaction(_proxy) as OptimisticProxy;
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
