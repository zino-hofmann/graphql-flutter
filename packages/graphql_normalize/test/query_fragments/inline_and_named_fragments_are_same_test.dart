import 'package:test/test.dart';
import 'package:gql/language.dart';

import 'package:graphql_normalize/normalize.dart';

void main() {
  group('Union Type Inline Fragments With Possible Types', () {
    final inlineFragmentQuery = parseString('''
      query TestQuery {
        booksAndAuthors {
          id
          __typename
          ... on Book {
            title
          }
          ... on Author {
            name
          }
        }
      }
    ''');
    final namedFragmentQuery = parseString('''
      query TestQuery {
        booksAndAuthors {
          id
          __typename
          ...BookFragment
          ...AuthorFragment
        }
      }
      fragment BookFragment on Book {
        title
      }
      fragment AuthorFragment on Author {
        name
      }
    ''');

    final data = {
      'booksAndAuthors': [
        {'id': '123', '__typename': 'Book', 'title': 'My awesome blog post'},
        {'id': '324', '__typename': 'Author', 'name': 'Nicole'}
      ]
    };
    final dataDeserializedWithoutPossibleTypes = {
      'booksAndAuthors': [
        {
          'id': '123',
          '__typename': 'Book',
          'title': 'My awesome blog post',
        },
        {'id': '324', '__typename': 'Author', 'name': 'Nicole'}
      ]
    };

    final normalizedMapWithPossibleTypes = {
      'Query': {
        'booksAndAuthors': [
          {'\$ref': 'Book:123'},
          {'\$ref': 'Author:324'}
        ]
      },
      'Book:123': {
        'id': '123',
        '__typename': 'Book',
        'title': 'My awesome blog post'
      },
      'Author:324': {'id': '324', '__typename': 'Author', 'name': 'Nicole'}
    };
    final normalizedMapWithoutPossibleTypes = {
      'Query': {
        'booksAndAuthors': [
          {'\$ref': 'Book:123'},
          {'\$ref': 'Author:324'}
        ]
      },
      'Book:123': {
        'id': '123',
        '__typename': 'Book',
        'title': 'My awesome blog post',
      },
      'Author:324': {
        'id': '324',
        '__typename': 'Author',
        'name': 'Nicole',
      }
    };
    final possibleTypes = {
      'BookAndAuthor': {'Book', 'Author'}
    };
    test('Produces same normalized object with possible types', () {
      final inlineNormalizedResult = <String, Map<String, dynamic>?>{};
      normalizeOperation(
        read: (dataId) => inlineNormalizedResult[dataId],
        write: (dataId, value) => inlineNormalizedResult[dataId] = value,
        document: inlineFragmentQuery,
        data: data,
        possibleTypes: possibleTypes,
      );
      final namedFragmentNormalizedResult = <String, Map<String, dynamic>?>{};
      normalizeOperation(
        read: (dataId) => namedFragmentNormalizedResult[dataId],
        write: (dataId, value) => namedFragmentNormalizedResult[dataId] = value,
        document: inlineFragmentQuery,
        data: data,
        possibleTypes: possibleTypes,
      );

      expect(
        inlineNormalizedResult,
        equals(namedFragmentNormalizedResult),
      );
      expect(
        inlineNormalizedResult,
        equals(normalizedMapWithPossibleTypes),
      );
    });
    test('Produces same normalized object without possible types', () {
      final inlineNormalizedResult = <String, Map<String, dynamic>?>{};
      normalizeOperation(
        read: (dataId) => inlineNormalizedResult[dataId],
        write: (dataId, value) => inlineNormalizedResult[dataId] = value,
        document: inlineFragmentQuery,
        data: data,
      );
      final namedFragmentNormalizedResult = <String, Map<String, dynamic>?>{};
      normalizeOperation(
        read: (dataId) => namedFragmentNormalizedResult[dataId],
        write: (dataId, value) => namedFragmentNormalizedResult[dataId] = value,
        document: inlineFragmentQuery,
        data: data,
      );

      expect(
        inlineNormalizedResult,
        equals(namedFragmentNormalizedResult),
      );
      expect(
        inlineNormalizedResult,
        equals(normalizedMapWithoutPossibleTypes),
      );
    });

    test('Produces correct nested data object with possible types', () {
      expect(
        denormalizeOperation(
          document: inlineFragmentQuery,
          read: (dataId) => normalizedMapWithPossibleTypes[dataId],
          possibleTypes: possibleTypes,
        ),
        equals(
          denormalizeOperation(
            document: namedFragmentQuery,
            read: (dataId) => normalizedMapWithPossibleTypes[dataId],
            possibleTypes: possibleTypes,
          ),
        ),
      );
      expect(
        denormalizeOperation(
          document: inlineFragmentQuery,
          read: (dataId) => normalizedMapWithPossibleTypes[dataId],
          possibleTypes: possibleTypes,
        ),
        equals(data),
      );
    });

    test('Produces correct nested data object without possible types', () {
      expect(
        denormalizeOperation(
          document: inlineFragmentQuery,
          read: (dataId) => normalizedMapWithoutPossibleTypes[dataId],
        ),
        equals(
          denormalizeOperation(
            document: namedFragmentQuery,
            read: (dataId) => normalizedMapWithoutPossibleTypes[dataId],
          ),
        ),
      );
      expect(
        denormalizeOperation(
          document: inlineFragmentQuery,
          read: (dataId) => normalizedMapWithoutPossibleTypes[dataId],
        ),
        equals(dataDeserializedWithoutPossibleTypes),
      );
    });
  });
}
