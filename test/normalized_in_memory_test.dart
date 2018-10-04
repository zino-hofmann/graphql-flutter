import 'package:test/test.dart';
import 'package:graphql_flutter/src/cache/normalized_in_memory.dart';

List<String> reference(String key) {
  return ['cache/reference', key];
}

final rawOperationKey = 'rawOperationKey';

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

final Map<String, Object> normalizedOperationData = <String, Object>{
  rawOperationKey: <String, Object>{
    'a': reference('A/1'),
  },
  'A/1': <String, Object>{
    'list': <Object>[1, 2, 3, reference('Item/4')],
    'b': reference('B/5'),
    'aField': <String, Object>{'field': false},
  },
  'Item/4': <String, Object>{
    '__typename': 'Item',
    'id': 4,
    'value': 4,
  },
  'B/5': <String, Object>{
    'c': reference('C/6'),
    'bField': <String, Object>{'field': false}
  },
  'C/6': <String, Object>{
    '__typename': 'C',
    'id': 5,
    'cField': 'value',
  },
};

void main() {
  group('Normalizes writes', () {
    final NormalizedInMemoryCache cache = NormalizedInMemoryCache(
      dataIdFromObject: defaultDataIdFromObject,
    );
    test('.write(data) normalizes input', () {
      cache.write(rawOperationKey, rawOperationData);
      cache._inMemoryCahce
      //expect( string.split(','), equals(['foo', 'bar', 'baz']));
    });

    test('.trim() removes surrounding whitespace', () {
      var string = '  foo ';
      expect(string.trim(), equals('foo'));
    });
  });

  group('int', () {
    test('.remainder() returns the remainder of division', () {
      expect(11.remainder(3), equals(2));
    });

    test('.toRadixString() returns a hex string', () {
      expect(11.toRadixString(16), equals('b'));
    });
  });
}
