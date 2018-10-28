import 'package:test/test.dart';
import 'package:graphql_flutter/src/cache/normalized_in_memory.dart';

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
  },
  'aField': <String, Object>{'field': false}
};

void main() {
  group('Normalizes writes', () {
    final NormalizedInMemoryCache cache = NormalizedInMemoryCache(
      dataIdFromObject: typenameDataIdFromObject,
    );
    test('.read .write round trip', () {
      cache.write(rawOperationKey, rawOperationData);
      expect(cache.read(rawOperationKey), equals(rawOperationData));
    });
    test('updating nested data changes top level operation', () {
      cache.write('C/6', updatedCValue);
      expect(cache.read(rawOperationKey), equals(updatedCOperationData));
    });
  });
}
