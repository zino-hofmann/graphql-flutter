import 'package:graphql/src/cache/_normalizing_data_proxy.dart';
import 'package:normalize/normalize.dart' show PartialDataException;
import 'package:test/test.dart';

import 'package:graphql/src/cache/cache.dart';

import '../helpers.dart';
import './cache_data.dart';

typedef CacheTransaction = GraphQLDataProxy Function(GraphQLDataProxy proxy);

void main() {
  if (debuggingUnexpectedTestFailures) {
    print(
      'DEBUGGING UNEXPECTED TEST FAILURES: $debuggingUnexpectedTestFailures.\n'
      'RUNNING TESTS WITH returnPartialData SET TO TRUE.\n',
    );
  }

  group('Normalizes writes', () {
    late GraphQLCache cache;
    setUp(() {
      cache = getTestCache();
    });
    test('.writeQuery .readQuery round trip', () {
      cache.writeQuery(basicTest.request, data: basicTest.data);
      expect(
        cache.readQuery(basicTest.request),
        equals(basicTest.data),
      );
    });

    test('typeless .writeQuery .readQuery round trip', () {
      cache.writeQuery(typelessTest.request, data: typelessTest.data);
      expect(
        cache.readQuery(typelessTest.request),
        equals(typelessTest.data),
      );
    });

    test('typeless custom dataIdFromObject', () {
      cache.writeQuery(typelessTest.request, data: typelessTest.data);
      expect(
        cache.readQuery(typelessTest.request),
        equals(typelessTest.data),
      );
    });

    test('.writeQuery should fail on missing fields', () {
      expect(
        () => cache.writeQuery(basicTest.request, data: <String, dynamic>{
          ...basicTest.data,
          'a': <String, dynamic>{
            ...(basicTest.data['a'] as Map<String, dynamic>),
            'b': <String, dynamic>{
              'id': 5,
            }
          },
        }),
        throwsA(isA<PartialDataException>().having(
          (e) => e.path,
          'An accurate path to the first missing subfield',
          ['a', 'b', '__typename'],
        )),
      );
    });

    test('updating nested normalized fragment changes top level operation', () {
      cache.writeQuery(basicTest.request, data: basicTest.data);
      final idFields = {
        '__typename': updatedCValue['__typename'],
        'id': updatedCValue['id'],
      };
      cache.writeFragment(
        updatedCFragment.asRequest(
          idFields: idFields,
        ),
        data: updatedCValue,
      );

      expect(
        cache.readQuery(basicTest.request),
        equals(updatedCBasicTestData),
      );

      expect(
        cache.readFragment(
          updatedCFragment.asRequest(
            idFields: idFields,
          ),
        ),
        updatedCValue,
      );
    });

    test('updating subset query only partially overrides superset query', () {
      cache.writeQuery(basicTest.request, data: basicTest.data);

      cache.writeQuery(
        basicTestSubsetAValue.request,
        data: basicTestSubsetAValue.data,
      );
      expect(
        cache.readQuery(basicTest.request),
        equals(getUpdatedSubsetOperationData()),
      );
    });
  });

  group('Handles cyclical references', () {
    final GraphQLCache cache = getTestCache();
    test('lazily reads cyclical references', () {
      cache.writeQuery(cyclicalTest.request, data: cyclicalTest.data);
      for (final normalized in cyclicalTest.normalizedEntities!) {
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
      for (final normalized in cyclicalTest.normalizedEntities!) {
        final dataId = "${normalized['__typename']}:${normalized['id']}";
        expect(cache.readNormalized(dataId), equals(normalized));
      }
    });
  });

  group(
    '.recordOptimisticTransaction',
    () {
      late GraphQLCache cache;

      setUp(() {
        cache = getTestCache();
      });

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
                proxy.readFragment(originalCFragment.asRequest(
                  idFields: idFields,
                )),
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

      recordCFragmentUpdate(GraphQLCache cache) =>
          cache.recordOptimisticTransaction(
            (proxy) => proxy
              ..writeFragment(
                updatedCFragment.asRequest(idFields: {
                  '__typename': updatedCValue['__typename'],
                  'id': updatedCValue['id'],
                }),
                data: updatedCValue,
              ),
            '2',
          );

      test(
        'updating nested normalized fragment changes top level operation',
        () {
          cache.writeQuery(basicTest.request, data: basicTest.data);
          recordCFragmentUpdate(cache);
          expect(
            cache.readQuery(basicTest.request),
            equals(updatedCBasicTestData),
          );
        },
      );

      recordBasicSubsetData(GraphQLCache cache) =>
          cache.recordOptimisticTransaction(
            (proxy) => proxy
              ..writeQuery(
                basicTestSubsetAValue.request,
                data: basicTestSubsetAValue.data,
              ),
            '3',
          );
      test(
        'updating subset query partially overrides superset query',
        () {
          cache.writeQuery(basicTest.request, data: basicTest.data);
          recordCFragmentUpdate(cache);
          recordBasicSubsetData(cache);
          expect(
            cache.readQuery(basicTest.request, optimistic: true),
            equals(getUpdatedSubsetOperationData(withUpdatedC: true)),
          );
        },
      );

      test(
        '.removeOptimisticPatch results in data from lower layers on readQuery',
        () {
          cache.writeQuery(basicTest.request, data: basicTest.data);
          recordCFragmentUpdate(cache);
          recordBasicSubsetData(cache);
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
    late GraphQLCache cache;
    setUp(() {
      cache = getTestCache();
    });
    test('.writeQuery .readQuery round trip', () {
      cache.writeQuery(fileVarsTest.request, data: fileVarsTest.data);
      expect(
        cache.readQuery(fileVarsTest.request),
        equals(fileVarsTest.data),
      );
    });
  });

  group('custom dataIdFromObject', () {
    /// Uses a `/` instead of the default `:`
    String? customDataIdFromObject(Object object) {
      if (object is Map<String, Object> &&
          object.containsKey('__typename') &&
          object.containsKey('id'))
        return "${object['__typename']}/${object['id']}";
      return null;
    }

    late GraphQLCache cache;
    setUp(() {
      cache = GraphQLCache(
        dataIdFromObject: customDataIdFromObject,
        partialDataPolicy: PartialDataCachePolicy.reject,
      );
    });

    test('.writeQuery .readQuery round trip', () {
      cache.writeQuery(basicTest.request, data: basicTest.data);
      expect(
        cache.readQuery(basicTest.request),
        equals(basicTest.data),
      );
    });

    test('typeless .writeQuery .readQuery round trip', () {
      cache.writeQuery(typelessTest.request, data: typelessTest.data);
      expect(
        cache.readQuery(typelessTest.request),
        equals(typelessTest.data),
      );
    });
  });
}
