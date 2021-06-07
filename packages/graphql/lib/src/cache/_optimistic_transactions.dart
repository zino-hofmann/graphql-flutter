/// Optimistic proxying and patching classes and typedefs used by `./cache.dart`
import 'dart:collection';

import 'package:graphql/src/utilities/helpers.dart';
import 'package:meta/meta.dart';

import 'package:graphql/src/cache/_normalizing_data_proxy.dart';
import 'package:graphql/src/cache/data_proxy.dart';

import 'package:graphql/src/cache/cache.dart'
    show GraphQLCache, PartialDataCachePolicy;

/// API for users to provide cache updates through
typedef CacheTransaction = GraphQLDataProxy Function(GraphQLDataProxy proxy);

/// An optimistic update recorded with [GraphQLCache.recordOptimisticTransaction],
/// identifiable through it's [id].
@immutable
class OptimisticPatch {
  const OptimisticPatch(this.id, this.data);
  final String id;
  final HashMap<String, dynamic> data;
}

/// Proxy by which users record [_OptimisticPatch]s though
/// [GraphQLCache.recordOptimisticTransaction].
///
/// Implements, and is exposed as, a [GraphQLDataProxy].
/// It's `optimistic` parameters default to `true`,
/// but the user can override them to read directly from the `store`.
class OptimisticProxy extends NormalizingDataProxy {
  OptimisticProxy(this.cache);

  GraphQLCache cache;

  /// Whether it is permissible to write partial data, as determined by [partialDataPolicy].
  ///
  /// Passed through to normalize. When [normalizeOperation] isn't passed [acceptPartialData],
  /// It will set missing fields to `null` if any part of a structurally valid query result is missing.
  @override
  bool get acceptPartialData =>
      cache.partialDataPolicy != PartialDataCachePolicy.reject;

  /// `typePolicies` to pass down to `normalize` (proxied from [cache])
  get typePolicies => cache.typePolicies;

  /// `possibleTypeOf` to pass down to `normalize` (proxied from [cache])
  get possibleTypes => cache.possibleTypes;

  /// Optional `dataIdFromObject` function to pass through to [normalize]
  /// (proxied from [cache])
  get dataIdFromObject => cache.dataIdFromObject;

  @override
  SanitizeVariables get sanitizeVariables => cache.sanitizeVariables;

  HashMap<String, dynamic> data = HashMap<String, dynamic>();

  @override
  dynamic readNormalized(String rootId, {bool? optimistic = true}) {
    if (!optimistic!) {
      return cache.readNormalized(rootId, optimistic: false);
    }
    // the cache calls `patch.data.containsKey(rootId)`,
    // so this is not an infinite loop
    return data[rootId] ?? cache.readNormalized(rootId, optimistic: true);
  }

  // TODO consider using store for optimistic patches
  /// Write normalized data into the patch,
  /// deeply merging maps with existing values
  ///
  /// Called from [writeQuery] and [writeFragment].
  void writeNormalized(String dataId, dynamic value) {
    if (value is Map<String, Object>) {
      final existing = data[dataId];
      data[dataId] =
          existing != null ? deeplyMergeLeft([existing, value]) : value;
    } else {
      data[dataId] = value;
    }
  }

  OptimisticPatch asPatch(String id) => OptimisticPatch(id, data);
}
