import 'package:test/test.dart';
import 'package:graphql_flutter/src/cache/normalized_in_memory.dart';
import 'package:graphql_flutter/src/cache/lazy_cache_map.dart';

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
      'a': <String, Object>{
        '__typename': 'A',
        'id': 1,
      },
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
  'a': <String>['@cache/reference', 'A/1'],
};

void main() {
  group('Normalizes writes', () {
    final NormalizedInMemoryCache cache = NormalizedInMemoryCache(
      dataIdFromObject: typenameDataIdFromObject,
    );
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
    final NormalizedInMemoryCache cache = NormalizedInMemoryCache(
      dataIdFromObject: typenameDataIdFromObject,
    );
    test('lazily reads cyclical references', () {
      cache.write(rawOperationKey, cyclicalOperationData);
      final LazyMap a = cache.read('A/1');
      expect(a.data, equals(cyclicalNormalizedA));
      final LazyMap b = a['b'];
      expect(b.data, equals(cyclicalNormalizedB));
    });
  });
}
