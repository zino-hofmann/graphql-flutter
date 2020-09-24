import 'package:graphql/src/cache/_normalizing_data_proxy.dart';
import 'package:test/test.dart';

import 'package:graphql/src/cache/cache.dart';

import '../helpers.dart';
import './cache_data.dart';

void main() {
  group('Normalizes writes', () {
    final GraphQLCache cache = getTestCache();
    test('.writeQuery .readQuery round trip', () {
      cache.writeQuery(basicTest.request, data: basicTest.data);
      expect(
        cache.readQuery(basicTest.request),
        equals(basicTest.data),
      );
    });
    test('updating nested normalized fragment changes top level operation', () {
      final idFields = {
        '__typename': updatedCValue['__typename'],
        'id': updatedCValue['id'],
      };
      cache.writeFragment(
        fragment: updatedCFragment,
        idFields: idFields,
        data: updatedCValue,
      );

      expect(
        cache.readQuery(basicTest.request),
        equals(updatedCBasicTestData),
      );

      expect(
        cache.readFragment(
          fragment: updatedCFragment,
          idFields: idFields,
        ),
        updatedCValue,
      );
    });

    test('updating subset query only partially overrides superset query', () {
      cache.writeQuery(
        basicTestSubsetAValue.request,
        data: basicTestSubsetAValue.data,
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
      cache.writeQuery(cyclicalTest.request, data: cyclicalTest.data);
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
      cache.writeQuery(cyclicalTest.request, data: cyclicalTest.data);
      for (final normalized in cyclicalTest.normalizedEntities) {
        final dataId = "${normalized['__typename']}:${normalized['id']}";
        expect(cache.readNormalized(dataId), equals(normalized));
      }
    });
  });

  group(
    '.recordOptimisticTransaction',
    () {
      final GraphQLCache cache = getTestCache();

      test(
        'OptimisticCache.readQuery and .readFragment pass through',
        () {
          cache.writeQuery(basicTest.request, data: basicTest.data);
          cache.broadcastRequested = false;
          cache.recordOptimisticTransaction(
            (proxy) {
              expect(
                proxy.readQuery(basicTest.request),
                equals(basicTest.data),
              );

              final idFields = {
                '__typename': originalCValue['__typename'],
                'id': originalCValue['id'],
              };

              expect(
                proxy.readFragment(
                  fragment: originalCFragment,
                  idFields: idFields,
                ),
                originalCValue,
              );

              expect(
                (proxy as NormalizingDataProxy).broadcastRequested,
                isFalse,
              );

              return proxy;
            },
            '1',
          );

          // no edits
          expect(cache.broadcastRequested, isFalse);
          expect(cache.optimisticPatches.first.id, equals('1'));
          expect(cache.optimisticPatches.first.data, equals({}));
        },
      );

      test(
        '.writeQuery, .readQuery(optimistic: true) round trip',
        () {
          cache.recordOptimisticTransaction(
            (proxy) => proxy
              ..writeQuery(
                basicTest.request,
                data: basicTest.data,
              ),
            '1',
          );
          expect(
            cache.readQuery(basicTest.request, optimistic: true),
            equals(basicTest.data),
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
            equals(updatedCBasicTestData),
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
                data: basicTestSubsetAValue.data,
              ),
            '3',
          );
          expect(
            cache.readQuery(basicTest.request, optimistic: true),
            equals(updatedSubsetOperationData),
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
            equals(basicTest.data),
          );
        },
      );
    },
  );

  group('Handles MultipartFile variables', () {
    final GraphQLCache cache = getTestCache();
    test('.writeQuery .readQuery round trip', () {
      cache.writeQuery(fileVarsTest.request, data: fileVarsTest.data);
      expect(
        cache.readQuery(fileVarsTest.request),
        equals(fileVarsTest.data),
      );
    });
  });
}
