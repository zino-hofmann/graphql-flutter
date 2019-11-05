import 'dart:async';

import 'package:meta/meta.dart';

import 'package:graphql/src/utilities/traverse.dart';
import 'package:graphql/src/utilities/helpers.dart';
import 'package:graphql/src/cache/in_memory.dart';
import 'package:graphql/src/cache/lazy_cache_map.dart';
import 'package:graphql/src/exceptions/exceptions.dart'
    show NormalizationException;

typedef DataIdFromObject = String Function(Object node);

typedef Normalizer = List<String> Function(Object node);

class NormalizedInMemoryCache extends InMemoryCache {
  NormalizedInMemoryCache({
    @required this.dataIdFromObject,
    this.prefix = '@cache/reference',
    FutureOr<String> storagePrefix,
  }) : super(storagePrefix: storagePrefix);

  DataIdFromObject dataIdFromObject;

  String prefix;

  bool _isReference(Object node) =>
      node is List && node.length == 2 && node[0] == prefix;

  Object _dereference(Object node) {
    if (node is List && _isReference(node)) {
      return read(node[1] as String);
    }

    return null;
  }

  LazyCacheMap lazilyDenormalized(
    Map<String, Object> data, [
    CacheState cacheState,
  ]) {
    return LazyCacheMap(
      data,
      dereference: _dereference,
      cacheState: cacheState,
    );
  }

  Object _denormalizingDereference(Object node) {
    if (node is List && _isReference(node)) {
      return denormalizedRead(node[1] as String);
    }

    return null;
  }

  // ~TODO~ ideally cyclical references would be noticed and replaced with null or something
  // @micimize: pretty sure I implemented the above
  /// eagerly dereferences all cache references.
  /// *WARNING* if your system allows cyclical references, this will break
  dynamic denormalizedRead(String key) {
    try {
      return Traversal(_denormalizingDereference).traverse(read(key));
    } catch (error) {
      if (error is StackOverflowError) {
        throw NormalizationException(
          '''
          Denormalization failed for $key this is likely caused by a circular reference.
          Please ensure dataIdFromObject returns a unique identifier for all possible entities in your system
          ''',
          error,
          key,
        );
      }
    }
  }

  @override
  void reset() {
    data.clear();
  }

  /*
    Dereferences object references,
    replacing them with cached instances
  */
  @override
  dynamic read(String key) {
    final Object value = super.read(key);
    return value is Map<String, Object> ? lazilyDenormalized(value) : value;
  }

  // get a normalizer for a given target map
  Normalizer _normalizerFor(Map<String, Object> into) {
    List<String> normalizer(Object node) {
      final dataId = dataIdFromObject(node);
      if (dataId != null) {
        return <String>[prefix, dataId];
      }
      return null;
    }

    return normalizer;
  }

  // [_normalizerFor] for this cache's data
  List<String> _normalize(Object node) {
    final String dataId = dataIdFromObject(node);
    if (dataId != null) {
      return <String>[prefix, dataId];
    }
    return null;
  }

  /// Writes included objects to provided Map,
  /// replacing discernable entities with references
  void writeInto(
    String key,
    Object value,
    Map<String, Object> into, [
    Normalizer normalizer,
  ]) {
    normalizer ??= _normalizerFor(into);
    if (value is Map<String, Object>) {
      final merged = _mergedWithExisting(into, key, value);
      final Traversal traversal = Traversal(
        normalizer,
        transformSideEffect: _traversingWriteInto(into),
      );
      // normalized the merged value
      into[key] = traversal.traverseValues(merged);
    } else {
      // writing non-map data to the store is allowed,
      // but there is no merging strategy
      into[key] = value;
    }
  }

  /// Writes included objects to store,
  /// replacing discernable entities with references
  @override
  void write(String key, Object value) {
    writeInto(key, value, data, _normalize);
  }
}

String typenameDataIdFromObject(Object object) {
  if (object is Map<String, Object> &&
      object.containsKey('__typename') &&
      object.containsKey('id')) {
    return "${object['__typename']}/${object['id']}";
  }
  return null;
}

/// Writing side effect for traverse
///
/// Essentially, we avoid problems with cyclical objects by
/// tracking seen nodes in the [Traversal],
/// and we pass this as a side effect to take advantage of that tracking
SideEffect _traversingWriteInto(Map<String, Object> into) {
  void sideEffect(Object ref, Object value, Traversal traversal) {
    final String key = (ref as List<String>)[1];
    if (value is Map<String, Object>) {
      final merged = _mergedWithExisting(into, key, value);
      into[key] = traversal.traverseValues(merged);
    } else {
      // writing non-map data to the store is allowed,
      // but there is no merging strategy
      into[key] = value;
      return;
    }
  }

  return sideEffect;
}

/// get the given value merged with any pre-existing map with the same key
Map<String, Object> _mergedWithExisting(
    Map<String, Object> into, String key, Map<String, Object> value) {
  final existing = into[key];
  return (existing is Map<String, Object>)
      ? deeplyMergeLeft([existing, value])
      : value;
}
