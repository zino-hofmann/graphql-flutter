import 'package:test/test.dart';
import 'package:gql/language.dart';

import 'package:graphql_normalize/normalize.dart';
import 'package:graphql_normalize/utils.dart';

Map<String, dynamic> get fullQueryData => {
      '__typename': 'Query',
      'posts': [
        {
          'id': '123',
          '__typename': 'Post',
          'title': null,
        }
      ]
    };

Map<String, dynamic> get partialQueryData {
  final partial = fullQueryData;
  partial['posts'][0].remove('title');
  return partial;
}

const normalizedQueryData = {
  'Query': {
    'posts': [
      {'\$ref': 'Post:123'}
    ]
  },
  'Post:123': {
    'id': '123',
    '__typename': 'Post',
    'title': null,
  },
};

final query = parseString('''
      query TestQuery {
        posts {
          __typename
          id
          title
        }
      }
    ''');

void main() {
  group('normalizeOperation acceptPartialData behavior', () {
    test('Accepts partial data by default', () {
      final normalizedResult = <String, Map<String, dynamic>?>{};

      normalizeOperation(
        read: (dataId) => normalizedResult[dataId],
        write: (dataId, value) => normalizedResult[dataId] = value,
        document: query,
        data: partialQueryData,
      );

      expect(
        normalizedResult,
        equals(normalizedQueryData),
      );
    });

    test('Rejects partial data when acceptPartialData=false', () {
      final normalizedResult = <String, Map<String, dynamic>?>{};

      expect(
        () => normalizeOperation(
          read: (dataId) => normalizedResult[dataId],
          write: (dataId, value) => normalizedResult[dataId] = value,
          acceptPartialData: false,
          document: query,
          data: partialQueryData,
        ),
        throwsA(isA<PartialDataException>().having(
          (e) => e.path,
          'An accurate path',
          ['posts', 'title'],
        )),
      );
    });

    test('Accepts explicit null when acceptPartialData=false', () {
      final normalizedResult = <String, Map<String, dynamic>?>{};

      normalizeOperation(
        read: (dataId) => normalizedResult[dataId],
        write: (dataId, value) => normalizedResult[dataId] = value,
        acceptPartialData: false,
        document: query,
        data: fullQueryData,
      );

      expect(
        normalizedResult,
        equals(normalizedQueryData),
      );
    });
  });

  group('validateOperationDataStructure', () {
    test('rejects partial data', () {
      expect(
        validateOperationDataStructure(
          handleException: true,
          document: query,
          data: partialQueryData,
        ),
        equals(false),
      );

      expect(
        () => validateOperationDataStructure(
          document: query,
          data: partialQueryData,
        ),
        throwsA(isA<PartialDataException>().having(
          (e) => e.path,
          'An accurate path',
          ['posts', 'title'],
        )),
      );
    });

    test('accepts valid data', () {
      expect(
        validateOperationDataStructure(
          document: query,
          data: fullQueryData,
        ),
        equals(true),
      );
    });

    test('rejects null data', () {
      expect(
        () => validateOperationDataStructure(data: null, document: query),
        throwsA(isA<PartialDataException>().having(
          (e) => e.path,
          'An empty path',
          [],
        )),
      );
    });
  });

  group('validateFragmentDataStructure', () {
    final fragment = parseString('''
      fragment foo on Post {
          id
          title
      }
    ''');

    test('rejects partial data', () {
      final partialFragmentData = {
        'id': '123',
        '__typename': 'Post',
      };

      expect(
        validateFragmentDataStructure(
          data: partialFragmentData,
          document: fragment,
          handleException: true,
        ),
        equals(false),
      );

      expect(
        () => validateFragmentDataStructure(
          data: partialFragmentData,
          document: fragment,
        ),
        throwsA(isA<PartialDataException>().having(
          (e) => e.path,
          'An accurate path',
          ['title'],
        )),
      );
    });

    test('accepts valid data', () {
      final fullFragmentData = {
        'id': '123',
        '__typename': 'Post',
        'title': null,
      };

      expect(
        validateFragmentDataStructure(
          data: fullFragmentData,
          document: fragment,
        ),
        equals(true),
      );
    });
    test('rejects null data', () {
      expect(
        () => validateFragmentDataStructure(data: null, document: fragment),
        throwsA(isA<PartialDataException>().having(
          (e) => e.path,
          'An empty path',
          [],
        )),
      );
    });
  });
}
