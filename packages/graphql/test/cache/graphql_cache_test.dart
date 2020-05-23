import 'package:test/test.dart';

import 'package:graphql/src/cache/cache.dart';

import '../helpers.dart';
import './cache_data.dart';

void main() {
  group('Normalizes writes', () {
    final GraphQLCache cache = getTestCache();
    test('.writeQuery .readQuery round trip', () {
      cache.writeQuery(basicTest.request, basicTest.data);
      expect(
        cache.readQuery(basicTest.request),
        equal(basicTest.data),
      );
    });
    test('updating nested normalized fragment changes top level operation', () {
      cache.writeFragment(
        fragment: updatedCFragment,
        idFields: {
          '__typename': updatedCValue['__typename'],
          'id': updatedCValue['id'],
        },
        data: updatedCValue,
      );
      expect(
        cache.readQuery(basicTest.request),
        equal(updatedCBasicTestData),
      );
    });

    test('updating subset query only partially overrides superset query', () {
      cache.writeQuery(
        basicTestSubsetAValue.request,
        basicTestSubsetAValue.data,
      );
      expect(
        cache.readQuery(basicTest.request),
        equal(updatedSubsetOperationData),
      );
    });
  });

  group('Handles cyclical references', () {
    final GraphQLCache cache = getTestCache();
    test('lazily reads cyclical references', () {
      cache.writeQuery(cyclicalTest.request, cyclicalTest.data);
      for (final normalized in cyclicalTest.normalizedEntities) {
        final dataId = "${normalized['__typename']}:${normalized['id']}";
        expect(cache.readNormalized(dataId), equal(normalized));
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
        expect(cache.readNormalized(dataId), equal(normalized));
      }
    });
  });

  group(
    '.recordOptimisticTransaction',
    () {
      final GraphQLCache cache = getTestCache();
      test(
        '.writeQuery, .readQuery(optimistic: true) round trip',
        () {
          cache.recordOptimisticTransaction(
            (proxy) => proxy
              ..writeQuery(
                basicTest.request,
                basicTest.data,
              ),
            '1',
          );
          expect(
            cache.readQuery(basicTest.request, optimistic: true),
            equal(basicTest.data),
          );
        },
      );

      test(
        'updating nested normalized fragment changes top level operation',
        () {
          cache.recordOptimisticTransaction(
            (proxy) => proxy
              ..writeFragment(
                fragment: updatedCFragment,
                idFields: {
                  '__typename': updatedCValue['__typename'],
                  'id': updatedCValue['id'],
                },
                data: updatedCValue,
              ),
            '2',
          );
          expect(
            cache.readQuery(basicTest.request),
            equal(updatedCBasicTestData),
          );
        },
      );

      test(
        'updating subset query only partially overrides superset query',
        () {
          cache.recordOptimisticTransaction(
            (proxy) => proxy
              ..writeQuery(
                basicTestSubsetAValue.request,
                basicTestSubsetAValue.data,
              ),
            '3',
          );
          expect(
            cache.readQuery(basicTest.request, optimistic: true),
            equal(updatedSubsetOperationData),
          );
        },
      );

      test(
        '.removeOptimisticPatch results in data from lower layers on readQuery',
        () {
          cache.removeOptimisticPatch('2');
          cache.removeOptimisticPatch('3');
          expect(
            cache.readQuery(basicTest.request, optimistic: true),
            equal(basicTest.data),
          );
        },
      );
    },
  );
}
