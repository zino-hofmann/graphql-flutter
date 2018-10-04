import 'package:meta/meta.dart';
import 'package:graphql_flutter/src/utilities/traverse.dart';
import 'package:graphql_flutter/src/cache/in_memory.dart';

typedef String DataIdFromObject(Object node);

class NormalizedInMemoryCache extends InMemoryCache {
  DataIdFromObject dataIdFromObject;
  String _prefix;

  NormalizedInMemoryCache({
    @required this.dataIdFromObject,
    String prefix = '@cache/reference',
  }) : _prefix = prefix;

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
    return traverse(value, _dereference);
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
