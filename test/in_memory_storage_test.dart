import 'dart:io' show Directory, File, Platform;
import 'package:test/test.dart';
import 'package:graphql_flutter/src/cache/in_memory.dart';

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

void main() {
  group('Normalizes writes', () {
    final Directory customStorageDirectory =
        Directory.systemTemp.createTempSync('file_test_');

    final InMemoryCache cache = InMemoryCache(
      customStorageDirectory: customStorageDirectory,
    );

    test('.write .read round trip', () async {
      cache.write(rawOperationKey, rawOperationData);
      await cache.save();
      cache.reset();
      await cache.restore();
      expect(cache.read(rawOperationKey), equals(rawOperationData));
    });

    test('saving concurrently wont error', () async {
      cache.write(rawOperationKey, rawOperationData);

      await Future.wait(<Future<void>>[
        cache.save(),
        cache.save(),
        cache.save(),
        cache.save(),
        cache.save(),
      ]);

      cache.reset();
      await cache.restore();
      expect(cache.read(rawOperationKey), equals(rawOperationData));
    });
  });
}
