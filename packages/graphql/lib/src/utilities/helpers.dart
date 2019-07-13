import 'package:graphql/src/cache/lazy_cache_map.dart'
    show LazyDereferencingMap, unwrapMap;

bool notNull(Object any) {
  return any != null;
}

bool areDifferentVariables(
  Map<String, dynamic> a,
  Map<String, dynamic> b,
) {
  if (a == null && b == null) {
    return false;
  }

  if (a == null || b == null) {
    return true;
  }

  if (a.length != b.length) {
    return true;
  }

  bool areDifferent = false;

  a.forEach((String key, dynamic value) {
    if ((!b.containsKey(key)) || b[key] != value) {
      areDifferent = true;
    }
  });

  return areDifferent;
}

Map<String, dynamic> _recursivelyAddAll(
  Map<String, dynamic> target,
  Map<String, dynamic> source,
) {
  target = Map.from(unwrapMap(target));
  source = unwrapMap(source);
  source.forEach((String key, dynamic value) {
    if (target.containsKey(key) &&
        target[key] is Map &&
        value != null &&
        value is Map<String, dynamic>) {
      target[key] = _recursivelyAddAll(
        target[key] as Map<String, dynamic>,
        value,
      );
    } else {
      target[key] = value;
    }
  });
  return target;
}

/// Deeply merges `maps` into a new map, merging nested maps recursively.
///
/// Paths in the rightmost maps override those in the earlier ones, so:
/// ```
/// print(deeplyMergeLeft([
///   {'keyA': 'a1'},
///   {'keyA': 'a2', 'keyB': 'b2'},
///   {'keyB': 'b3'}
/// ]));
/// // { keyA: a2, keyB: b3 }
/// ```
///
/// All given [LazyDereferencingMap] instances will be unwrapped
Map<String, dynamic> deeplyMergeLeft(
  Iterable<Map<String, dynamic>> maps,
) {
  // prepend an empty literal for functional immutability
  return (<Map<String, dynamic>>[{}]..addAll(maps)).reduce(_recursivelyAddAll);
}
