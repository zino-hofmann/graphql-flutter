/// Optimistic proxying and patching classes and typedefs used by `./cache.dart`
import 'dart:collection';

import 'package:meta/meta.dart';

import 'package:graphql/src/cache/normalizing_data_proxy.dart';
import 'package:graphql/src/cache/data_proxy.dart';

import 'package:graphql/src/cache/cache.dart' show GraphQLCache;

/// API for users to provide cache updates through
typedef CacheTransaction = GraphQLDataProxy Function(GraphQLDataProxy proxy);

/// An optimistic update recorded with [GraphQLCache.recordOptimisticTransaction],
/// identifiable through it's [id].
@immutable
class OptimisticPatch extends Object {
  const OptimisticPatch(this.id, this.data);
  final String id;
  final HashMap<String, dynamic> data;
}

/// Proxy by which users record [_OptimisticPatch]s though
/// [GraphQLCache.recordOptimisticTransaction].
///
/// Implements, and is exposed as, a [GraphQLDataProxy].
/// It's `optimistic` paraemeters default to `true`,
/// but the user can override them to read directly from the `store`.
class OptimisticProxy extends NormalizingDataProxy {
  OptimisticProxy(this.cache);

  GraphQLCache cache;

  HashMap<String, dynamic> data = HashMap<String, dynamic>();

  @override
  dynamic readNormalized(String rootId, {bool optimistic = true}) {
    if (!optimistic) {
      return cache.readNormalized(rootId, optimistic: false);
    }
    // the cache calls `patch.data.containsKey(rootId)`,
    // so this is not an infinite loop
    return data[rootId] ?? cache.readNormalized(rootId, optimistic: true);
  }

  @override
  void writeNormalized(String dataId, dynamic value) => data[dataId] = value;

  OptimisticPatch asPatch(String id) => OptimisticPatch(id, data);
}
