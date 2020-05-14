import 'package:test/test.dart';

import 'package:graphql/src/cache/cache.dart';

import '../helpers.dart';
import 'normalization_data.dart';

void main() {
  group('Normalizes writes', () {
    final GraphQLCache cache = getTestCache();
    test('.writeQuery .readQuery round trip', () {
      cache.writeQuery(basicTest.request, basicTest.data);
      expect(
        cache.readQuery(basicTest.request),
        equals(basicTest.data),
      );
    });
    test('updating nested normalized data changes top level operation', () {
      cache.writeNormalized('C:6', updatedCValue);
      expect(
        cache.readQuery(basicTest.request),
        equals(updatedCBasicTestData),
      );
    });
    test('updating subset query only partially overrides superset query', () {
      cache.writeQuery(
        basicTestSubsetAValue.request,
        basicTestSubsetAValue.data,
      );
      expect(
        cache.readQuery(basicTest.request),
        equals(updatedSubsetOperationData),
      );
    });
  });

  group('Handles cyclical references', () {
    final GraphQLCache cache = getTestCache();
    test('lazily reads cyclical references', () {
      cache.writeQuery(cyclicalTest.request, cyclicalTest.data);
      for (final normalized in cyclicalTest.normalizedEntities) {
        final dataId = "${normalized['__typename']}:${normalized['id']}";
        expect(cache.readNormalized(dataId), equals(normalized));
      }
    });
  });

  group('Handles Object/pointer self-references/cycles', () {
    final GraphQLCache cache = getTestCache();
    test('correctly reads cyclical references', () {
      cyclicalTest.data = cyclicalObjOperationData;
      cache.writeQuery(cyclicalTest.request, cyclicalTest.data);
      for (final normalized in cyclicalTest.normalizedEntities) {
        final dataId = "${normalized['__typename']}:${normalized['id']}";
        expect(cache.readNormalized(dataId), equals(normalized));
      }
    });
  });
}
