import 'dart:async';
import 'dart:io' show Directory;
import 'package:test/test.dart';
import 'package:graphql/src/cache/in_memory.dart';

const String aKey = 'aKey';
const String bKey = 'bKey';
const String cKey = 'cKey';
const String dKey = 'dKey';
const String eKey = 'eKey';

final Map<String, Object> aData = <String, Object>{
  'a': <String, Object>{
    '__typename': 'A',
  }
};

final Map<String, Object> bData = <String, Object>{
  'b': <String, Object>{
    '__typename': 'B',
  }
};

final Map<String, Object> cData = <String, Object>{
  'c': <String, Object>{
    '__typename': 'C',
  }
};

final Map<String, Object> dData = <String, Object>{
  'd': <String, Object>{
    '__typename': 'D',
  }
};

final Map<String, Object> eData = <String, Object>{
  'e': <String, Object>{
    '__typename': 'E',
  }
};

final Directory customStorageDirectory =
    Directory.systemTemp.createTempSync('file_test_');

void main() {
  group('Normalizes writes', () {
    test('.write .read round trip', () async {
      final InMemoryCache cache = InMemoryCache(
        storageProvider: () => customStorageDirectory,
      );
      cache.write(aKey, aData);
      await cache.save();
      cache.reset();
      await cache.restore();
      expect(cache.read(aKey), equals(aData));
    });

    test('saving concurrently wont error', () async {
      final InMemoryCache cache = InMemoryCache(
        storageProvider: () => customStorageDirectory,
      );
      cache.write(aKey, aData);
      cache.write(bKey, bData);
      cache.write(cKey, cData);
      cache.write(dKey, dData);
      cache.write(eKey, eData);

      await Future.wait(<Future<void>>[
        cache.save(),
        cache.save(),
        cache.save(),
        cache.save(),
        cache.save(),
      ]);

      cache.reset();
      await cache.restore();

      expect(cache.read(aKey), equals(aData));
      expect(cache.read(bKey), equals(bData));
      expect(cache.read(cKey), equals(cData));
      expect(cache.read(dKey), equals(dData));
      expect(cache.read(eKey), equals(eData));
    });
  });
}
