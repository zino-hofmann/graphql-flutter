import 'package:graphql/src/cache/lazy_cache_map.dart'
    show LazyDereferencingMap, unwrapMap;

typedef DataIdFromObject = String Function(Object node);

bool notNull(Object any) {
  return any != null;
}

/// instance
/// ```
/// Map<String, dynamic>val = {"abc":true};
/// areDifferentVariables(null,val); // true
/// areDifferentVariables({"abc":true},val); // false
/// ```
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

/// instances
/// ```
/// Map<String, dynamic> target = {"onSave":"true","onUpdate":123,"onUpdate2":{"idNo":"231","type":"IDCARD"}};
/// Map<String, dynamic> source = {"onUpdate2":{"idNo":"233"},"onInsert":"abcd","onUpdate":{"1":123,"2":234}};
/// 
/// _recursivelyAddAll(target,source);
/// // {onSave: true, onUpdate: {1: 123, 2: 234}, onUpdate2: {idNo: 233, type: IDCARD}, onInsert: abcd}
/// ```
Map<String, dynamic> _recursivelyAddAll(
  Map<String, dynamic> target,
  Map<String, dynamic> source,
) {
  target = unwrapMap(target);
  source = unwrapMap(source);
  source.forEach((String key, dynamic value) {
    if (target.containsKey(key) &&
        target[key] is Map &&
        value != null &&
        value is Map<String, dynamic>) {
      _recursivelyAddAll(
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
  return (<Map<String, dynamic>>[<String, dynamic>{}]..addAll(maps))
      .reduce(_recursivelyAddAll);
}

/// instance
/// case1
/// 
/// ```
/// Map<String, Object> map={"attr1":"v1","attr2":'v2','expand':123,'attr3':'v3'};
/// List<String> keys = ["attr1","attr2","attr3"];
/// print(compositData(keys,'.')(map)); // v1.v2.v3
/// ```
/// case2
/// 
/// ```
/// Map<String, Object> map={"attr1":"v1","attr2":'v2','attr3':'v3'};
/// List<String> keys = ["attr1","expand"];
/// print(compositData(keys,'/')(map)); // null
/// ```
/// case3
///```
/// Map<String, Object> map={"__typename":"v1","id":'v2','attr3':'v3'};
/// print(compositData()(map)); // v1/v2/v3
/// ```
DataIdFromObject compositData([ List<String> keys= DEFAULT_KEYS,  String seperator = DEFAULT_SEPERATOR ]) {
  return (Object object) {
    if (objectIsCanComposit(object, keys)) 
      return datasToString(keys, object as Map<String, Object>, seperator);
    return null;
  };
}

/// instance
/// 
/// ```
/// Map<String, Object> map={"attr1":"v1","attr2":'v2','expand':123,'attr3':'v3'};
/// List<String> keys = ["attr1","attr2","attr3"];
/// print(containsAll(map,keys)); // true
/// ```
/// ```
/// Map<String, Object> map={"attr1":"v1","attr2":'v2','attr3':'v3'};
/// List<String> keys = ["expand"];
/// print(containsAll(map,keys)); // false
/// ```
bool containsAllKeys(Map<String, Object> map, List<String> keys) =>
  keys.where((String s) => !map.containsKey(s)).isEmpty;

const List<String> DEFAULT_KEYS = [ '__typename', 'id' ];
const String DEFAULT_SEPERATOR = '/';

String datasToString(List<String> keys, Map<String, Object> object, String seperator) => keys.map((String key) => object[key].toString()).join(seperator);

bool objectIsCanComposit(Object object, List<String> keys) {
  return object is Map<String, Object> &&
      containsAllKeys(object, keys);
}
