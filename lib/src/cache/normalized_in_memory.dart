import 'package:meta/meta.dart';
import 'package:graphql_flutter/src/utilities/traverse.dart';
import 'package:graphql_flutter/src/cache/in_memory.dart';

typedef String DataIdFromObject(Object node);

class NormalizationException implements Exception {
  NormalizationException(this.cause, this.overflowError, this.value);

  StackOverflowError overflowError;
  String cause;
  Object value;

  String get message => cause;
}

class NormalizedInMemoryCache extends InMemoryCache {
  NormalizedInMemoryCache({
    @required this.dataIdFromObject,
    String prefix = '@cache/reference',
  }) : _prefix = prefix;

  DataIdFromObject dataIdFromObject;
  String _prefix;

  Object _dereference(Object node) {
    if (node is List && node.length == 2 && node[0] == _prefix) {
      return read(node[1]);
    }

    return null;
  }

  /*
    Derefrences object references,
    replacing them with cached instances
  */
  @override
  dynamic read(String key) {
    final Object value = super.read(key);

    try {
      return traverse(value, _dereference);
    } catch (error) {
      if (error is StackOverflowError) {
        throw NormalizationException(
          '''
          Dereferencing failed for $value this is likely caused by a circular reference.
          Please ensure dataIdFromObject returns a unique identifier for all possible entities in your system
          ''',
          error,
          value,
        );
      }
    }
  }

  List<String> _normalize(Object node) {
    final String dataId = dataIdFromObject(node);

    if (dataId != null) {
      write(dataId, node);
      return <String>[_prefix, dataId];
    }

    return null;
  }

  /*
    Writes included objects to store,
    replacing them with references
  */
  @override
  void write(String key, Object value) {
    final Object normalized = traverseValues(value, _normalize);
    super.write(key, normalized);
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
