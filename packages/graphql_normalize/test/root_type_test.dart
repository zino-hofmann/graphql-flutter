import 'package:graphql_normalize/utils.dart';
import 'package:test/test.dart';
import 'package:gql/language.dart';

import 'package:graphql_normalize/normalize.dart';

void main() {
  group('Root Fragments', () {
    final query = parseString('''
      fragment AuthorFragment on Query {
        __typename
        person {
          __typename
          id
          name
          age
        }
      }
    ''');
    final normalizedData = {
      'Person:1': {'__typename': 'Person', 'id': 1, 'name': 'Bob', 'age': null},
      'Query': {
        '__typename': 'Query',
        'person': {r'$ref': 'Person:1'}
      }
    };
    final data = {
      '__typename': 'Query',
      'person': {
        'id': 1,
        '__typename': 'Person',
        'name': 'Bob',
        'age': null,
      }
    };
    test('Produces correct normalized object', () {
      final normalizedResult = <String, Map<String, dynamic>?>{};
      normalizeFragment(
        read: (dataId) => normalizedResult[dataId],
        write: (dataId, value) => normalizedResult[dataId] = value,
        document: query,
        data: data,
        possibleTypes: {
          'Person': {'Author'}
        },
        idFields: {},
      );

      expect(
        normalizedResult,
        equals(normalizedData),
      );
    });
    test('Produces correct denormalized object', () {
      final result = denormalizeFragment(
        read: (dataId) => normalizedData[dataId],
        document: query,
        possibleTypes: {
          'Person': {'Author'}
        },
        idFields: {},
      );

      expect(
        result,
        equals(data),
      );
    });
    test('Validate Fragment', () {
      validateFragmentDataStructure(document: query, data: data);
    });
  });

  group('Nested root types', () {
    final document = parseString('''
          query Q {
            __typename
            name
            q {
              __typename
              age
            }
          }

        ''');
    final data = {
      '__typename': 'Query',
      'name': 'Bob',
      'q': {'__typename': 'Query', 'age': 31}
    };
    final normalizedData = {
      'Query': {
        '__typename': 'Query',
        'q': {r'$ref': 'Query'},
        'name': 'Bob',
        'age': 31
      }
    };
    test('Normalizes nested root types', () {
      final normalized = <String, Map<String, dynamic>?>{};
      normalizeOperation(
        write: (key, data) {
          normalized[key] = data;
        },
        read: (key) => normalized[key],
        document: document,
        data: data,
      );
      expect(normalized, equals(normalizedData));
    });
    test('Denormalizes nested root types', () {
      expect(
          denormalizeOperation(
            read: (key) => normalizedData[key],
            document: document,
          ),
          equals(data));
    });
    test('Validate Query', () {
      validateOperationDataStructure(document: document, data: data);
    });
  });
}
