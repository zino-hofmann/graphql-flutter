import 'package:collection/collection.dart' show IterableExtension;
import 'package:graphql/src/cache/_normalizing_data_proxy.dart';
import 'package:meta/meta.dart';

import 'package:graphql/src/utilities/helpers.dart';
import 'package:graphql/src/cache/store.dart';

import 'package:graphql/src/cache/_optimistic_transactions.dart';
import 'package:normalize/normalize.dart';

export 'package:graphql/src/cache/data_proxy.dart';
export 'package:graphql/src/cache/store.dart';
export 'package:graphql/src/cache/hive_store.dart';
export 'package:graphql/src/cache/fragment.dart';

typedef VariableEncoder = Object Function(Object t);

/// Optimistic GraphQL Entity cache with [normalize] [TypePolicy] support
/// and configurable [store].
///
/// **NOTE**: The default [InMemoryStore] does _not_ persist to disk.
/// The recommended store for persistent environments is the [HiveStore].
///
/// [dataIdFromObject] and [typePolicies] are passed down to [normalize] operations, which say:
/// > IDs are determined by the following:
/// >
/// > 1. If a `TypePolicy` is provided for the given type, it's `TypePolicy.keyFields` are used.
/// > 2. If a `dataIdFromObject` funciton is provided, the result is used.
/// > 3. The `id` or `_id` field (respectively) are used.
class GraphQLCache extends NormalizingDataProxy {
  GraphQLCache({
    Store? store,
    this.dataIdFromObject,
    this.typePolicies = const {},
    this.possibleTypes = const {},
    this.partialDataPolicy = PartialDataCachePolicy.acceptForOptimisticData,
    Object? Function(Object?) sanitizeVariables = sanitizeFilesForCache,
  })  : sanitizeVariables = variableSanitizer(sanitizeVariables),
        store = store ?? InMemoryStore();

  /// Stores the underlying normalized data. Defaults to an [InMemoryStore]
  ///
  /// **WARNING**: Directly editing the contents of the store will not automatically
  /// rebroadcast operations.
  final Store store;

  /// Determines how partial data should be handled when written to the cache
  ///
  /// [acceptForOptimisticData] is the default and recommended, as it provides
  /// the best balance between safety and usability.
  final PartialDataCachePolicy partialDataPolicy;

  /// Whether it is permissible to write partial data, as determined by [partialDataPolicy].
  ///
  /// Passed through to normalize. When [normalizeOperation] isn't passed [acceptPartialData],
  /// It will simply return `null` if any part of the query can't be constructed.
  @override
  bool get acceptPartialData =>
      partialDataPolicy == PartialDataCachePolicy.accept;

  /// `typePolicies` to pass down to [normalize]
  final Map<String, TypePolicy> typePolicies;

  /// `possibleTypes` to pass down to [normalize]
  final Map<String, Set<String>> possibleTypes;

  /// Optional `dataIdFromObject` function to pass through to [normalize]
  final DataIdResolver? dataIdFromObject;

  /// Input variable sanitizer for referencing custom scalar types in cache keys.
  ///
  /// Defaults to [sanitizeFilesForCache]. Can be set to `null` to disable sanitization.
  /// If present, a sanitizer will be built with [variableSanitizer]
  @override
  final SanitizeVariables sanitizeVariables;

  /// Tracks the number of ongoing transactions (cache updates)
  /// to prevent rebroadcasts until they are completed.
  ///
  /// **NOTE**: Does not track network calls
  @protected
  int inflightOptimisticTransactions = 0;

  /// Whether a cache operation has requested a broadcast and it is safe to do.
  ///
  /// The caller must [claimExectution] to clear the [broadcastRequested] flag.
  ///
  /// This is not meant to be called outside of the [QueryManager]
  bool shouldBroadcast({bool claimExecution = false}) {
    if (inflightOptimisticTransactions == 0 && broadcastRequested) {
      if (claimExecution) {
        broadcastRequested = false;
      }
      return true;
    }
    return false;
  }

  /// List of patches recorded through [recordOptimisticTransaction]
  ///
  /// They are applied in ascending order,
  /// thus data in `last` will overwrite that in `first`
  /// if there is a conflict
  @protected
  @visibleForTesting
  List<OptimisticPatch> optimisticPatches = [];

  /// Reads dereferences an entity from the first valid optimistic layer,
  /// defaulting to the base internal HashMap.
  Map<String, dynamic>? readNormalized(
    String rootId, {
    bool? optimistic = true,
  }) {
    var value = store.get(rootId);

    if (!optimistic!) {
      return value;
    }

    for (final patch in optimisticPatches) {
      if (patch.data.containsKey(rootId)) {
        final patchData = patch.data[rootId];
        if (value is Map<String, Object> && patchData is Map<String, Object>) {
          value = deeplyMergeLeft([
            value,
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

  /// Write normalized data into the cache,
  /// deeply merging maps with existing values
  ///
  /// Called from [writeQuery] and [writeFragment].
  void writeNormalized(String dataId, Map<String, dynamic>? value) {
    if (value is Map<String, Object>) {
      final existing = store.get(dataId);
      store.put(
        dataId,
        existing != null ? deeplyMergeLeft([existing, value]) : value,
      );
    } else {
      store.put(dataId, value);
    }
  }

  String? _parentPatchId(String id) {
    final List<String> parts = id.split('.');
    if (parts.length > 1) {
      return parts.first;
    }
    return null;
  }

  bool _patchExistsFor(String id) =>
      optimisticPatches.firstWhereOrNull(
        (patch) => patch.id == id,
      ) !=
      null;

  /// avoid race conditions from slow updates
  ///
  /// if a server result is returned before an optimistic update is finished,
  /// that update is discarded
  bool _safeToAdd(String id) {
    final String? parentId = _parentPatchId(id);
    return parentId == null || _patchExistsFor(parentId);
  }

  // TODO does patch hierachy still makes sense
  /// Record the given [transaction] into a patch with the id [addId]
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
    inflightOptimisticTransactions += 1;
    final _proxy = transaction(OptimisticProxy(this)) as OptimisticProxy;
    if (_safeToAdd(addId)) {
      optimisticPatches.add(_proxy.asPatch(addId));
      broadcastRequested = broadcastRequested || _proxy.broadcastRequested;
    }
    inflightOptimisticTransactions -= 1;
  }

  /// Remove a given patch from the list
  ///
  /// This will also remove all "nested" patches, such as `$queryId.update`
  /// (see [recordOptimisticTransaction])
  ///
  /// This allows for hierarchical optimism that is automatically cleaned up
  /// without having to tightly couple optimistic changes
  void removeOptimisticPatch(String removeId) {
    optimisticPatches.removeWhere(
      (patch) => patch.id == removeId || _parentPatchId(patch.id) == removeId,
    );
    broadcastRequested = true;
  }
}

/// Determines how partial data should be handled when written to the cache
///
/// [acceptForOptimisticData] is the default and recommended, as it provides
/// the best balance between safety and usability.
enum PartialDataCachePolicy {
  /// Accept partial data in all cases (default).
  accept,

  /// Accept partial data, but only for transient optimistic writes made with
  /// [GraphQLCache.recordOptimisticTransaction]
  acceptForOptimisticData,

  /// Reject partial data in all cases.
  reject,
}
