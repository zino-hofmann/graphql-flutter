import 'package:test/test.dart';

import 'package:graphql/src/cache/normalized_in_memory.dart';
import 'package:graphql/src/cache/lazy_cache_map.dart';

List<String> reference(String key) {
  return <String>['cache/reference', key];
}

const String rawOperationKey = 'rawOperationKey';

final Map<String, Object> rawOperationData = <String, Object>{
  'a': <String, Object>{
    '__typename': 'A',
    'id': 1,
    'list': <Object>[
      1,
      2,
      3,
      <String, Object>{
        '__typename': 'Item',
        'id': 4,
        'value': 4,
      }
    ],
    'b': <String, Object>{
      '__typename': 'B',
      'id': 5,
      'c': <String, Object>{
        '__typename': 'C',
        'id': 6,
        'cField': 'value',
      },
      'bField': <String, Object>{'field': true}
    },
    'd': <String, Object>{
      'id': 9,
      'dField': <String, Object>{'field': true}
    },
  },
  'aField': <String, Object>{'field': false}
};

final Map<String, Object> updatedCValue = <String, Object>{
  '__typename': 'C',
  'id': 6,
  'new': 'field',
  'cField': 'changed value',
};

final Map<String, Object> updatedCOperationData = <String, Object>{
  'a': <String, Object>{
    '__typename': 'A',
    'id': 1,
    'list': <Object>[
      1,
      2,
      3,
      <String, Object>{
        '__typename': 'Item',
        'id': 4,
        'value': 4,
      }
    ],
    'b': <String, Object>{
      '__typename': 'B',
      'id': 5,
      'c': updatedCValue,
      'bField': <String, Object>{'field': true}
    },
    'd': <String, Object>{
      'id': 9,
      'dField': <String, Object>{'field': true}
    },
  },
  'aField': <String, Object>{'field': false}
};

final Map<String, Object> subsetAValue = <String, Object>{
  'a': <String, Object>{
    '__typename': 'A',
    'id': 1,
    'list': <Object>[
      5,
      6,
      7,
      <String, Object>{
        '__typename': 'Item',
        'id': 8,
        'value': 8,
      }
    ],
    'd': <String, Object>{
      'id': 10,
    },
  },
};

final Map<String, Object> updatedSubsetOperationData = <String, Object>{
  'a': <String, Object>{
    '__typename': 'A',
    'id': 1,
    'list': <Object>[
      5,
      6,
      7,
      <String, Object>{
        '__typename': 'Item',
        'id': 8,
        'value': 8,
      }
    ],
    'b': <String, Object>{
      '__typename': 'B',
      'id': 5,
      'c': updatedCValue,
      'bField': <String, Object>{'field': true}
    },
    'd': <String, Object>{
      'id': 10,
      'dField': <String, Object>{'field': true}
    },
  },
  'aField': <String, Object>{'field': false}
};

final Map<String, Object> cyclicalOperationData = <String, Object>{
  'a': <String, Object>{
    '__typename': 'A',
    'id': 1,
    'b': <String, Object>{
      '__typename': 'B',
      'id': 5,
      'as': [
        <String, Object>{
          '__typename': 'A',
          'id': 1,
        },
      ]
    },
  },
};

final Map<String, Object> cyclicalNormalizedA = <String, Object>{
  '__typename': 'A',
  'id': 1,
  'b': <String>['@cache/reference', 'B/5'],
};

final Map<String, Object> cyclicalNormalizedB = <String, Object>{
  '__typename': 'B',
  'id': 5,
  'as': [
    <String>['@cache/reference', 'A/1']
  ],
};

Map<String, Object> get cyclicalObjOperationData {
  Map<String, Object> a;
  Map<String, Object> b;
  a = {
    '__typename': 'A',
    'id': 1,
  };
  b = <String, Object>{
    '__typename': 'B',
    'id': 5,
    'as': [a]
  };
  a['b'] = b;
  return {'a': a};
}

final Map<String, Object> cyclicalObjNormalizedA = {
  '__typename': 'A',
  'id': 1,
  'b': <String>['@cache/reference', 'B/5'],
};

final Map<String, Object> cyclicalObjNormalizedB = {
  '__typename': 'B',
  'id': 5,
  'as': [
    <String>['@cache/reference', 'A/1']
  ],
};

NormalizedInMemoryCache getTestCache() => NormalizedInMemoryCache(
      dataIdFromObject: typenameDataIdFromObject,
    );

void main() {
  group('Normalizes writes', () {
    final NormalizedInMemoryCache cache = getTestCache();
    test('.write .readDenormalize round trip', () {
      cache.write(rawOperationKey, rawOperationData);
      expect(cache.denormalizedRead(rawOperationKey), equals(rawOperationData));
    });
    test('updating nested data changes top level operation', () {
      cache.write('C/6', updatedCValue);
      expect(
        cache.denormalizedRead(rawOperationKey),
        equals(updatedCOperationData),
      );
    });
    test('updating subset query does not override superset query', () {
      cache.write('anotherUnrelatedKey', subsetAValue);
      expect(cache.read(rawOperationKey), equals(updatedSubsetOperationData));
    });
  });
  group('Normalizes writes', () {
    final NormalizedInMemoryCache cache = getTestCache();
    test('lazily reads cyclical references', () {
      cache.write(rawOperationKey, cyclicalOperationData);
      final LazyCacheMap a = cache.read('A/1') as LazyCacheMap;
      expect(a.data, equals(cyclicalNormalizedA));
      final LazyCacheMap b = a['b'] as LazyCacheMap;
      expect(b.data, equals(cyclicalNormalizedB));
    });
  });

  group('Handles Object/pointer self-references/cycles', () {
    final NormalizedInMemoryCache cache = getTestCache();
    test('lazily reads cyclical references', () {
      cache.write(rawOperationKey, cyclicalObjOperationData);
      final LazyCacheMap a = cache.read('A/1') as LazyCacheMap;
      expect(a.data, equals(cyclicalObjNormalizedA));
      final LazyCacheMap b = a['b'] as LazyCacheMap;
      expect(b.data, equals(cyclicalObjNormalizedB));
    });
  });

  group('Resets cache correctly', () {
    final NormalizedInMemoryCache cache = getTestCache();
    test('resets cache correctly when cache.reset() is called', () {
      cache.write(rawOperationKey, cyclicalObjOperationData);
      final LazyCacheMap a = cache.read('A/1') as LazyCacheMap;
      expect(a.data, equals(cyclicalObjNormalizedA));
      cache.reset();
      final resetA = cache.read('A/1');
      expect(resetA, equals(null));
    });
  });
}
