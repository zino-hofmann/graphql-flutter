import 'package:test/test.dart';
import 'package:gql/language.dart';

import 'package:graphql_normalize/normalize.dart';
import '../shared_data.dart';

void main() {
  group('Key Fields', () {
    final query = parseString('''
      query TestQuery {
        __typename
        posts {
          id
          __typename
          author {
            id
            __typename
            name
          }
          title
          comments {
            id
            __typename
            commenter {
              id
              __typename
              name
            }
          }
        }
      }
    ''');

    group('with correct keyFields', () {
      final normalizedMap = {
        'Query': {
          '__typename': 'Query',
          'posts': [
            {
              '\$ref':
                  'Post:{"author":{"name":"Paul"},"id":"123","title":"My awesome blog post"}'
            }
          ]
        },
        'Post:{"author":{"name":"Paul"},"id":"123","title":"My awesome blog post"}':
            {
          'id': '123',
          '__typename': 'Post',
          'author': {'\$ref': 'Author:1'},
          'title': 'My awesome blog post',
          'comments': [
            {'\$ref': 'Comment:324'}
          ]
        },
        'Author:1': {'id': '1', '__typename': 'Author', 'name': 'Paul'},
        'Comment:324': {
          'id': '324',
          '__typename': 'Comment',
          'commenter': {'\$ref': 'Author:2'}
        },
        'Author:2': {'id': '2', '__typename': 'Author', 'name': 'Nicole'}
      };

      final typePolicies = {
        'Post': TypePolicy(
          keyFields: {
            'id': true,
            'title': true,
            'author': {
              'name': true,
            },
          },
        )
      };

      test('Produces correct normalized object', () {
        final normalizedResult = <String, Map<String, dynamic>?>{};
        normalizeOperation(
          read: (dataId) => normalizedResult[dataId],
          write: (dataId, value) => normalizedResult[dataId] = value,
          document: query,
          data: sharedResponse,
          typePolicies: typePolicies,
        );

        expect(
          normalizedResult,
          equals(normalizedMap),
        );
      });

      test('Produces correct nested data object', () {
        expect(
          denormalizeOperation(
            document: query,
            read: (dataId) => normalizedMap[dataId],
            typePolicies: typePolicies,
          ),
          equals(sharedResponse),
        );
      });
    });

    group('with invalid keyField values', () {
      final normalizedMap = {
        'Query': {
          '__typename': 'Query',
          'posts': [
            {'\$ref': 'Post:{"author":{"name":"Paul"},"id":"123"}'}
          ]
        },
        'Post:{"author":{"name":"Paul"},"id":"123"}': {
          'id': '123',
          '__typename': 'Post',
          'author': {'\$ref': 'Author:1'},
          'title': 'My awesome blog post',
          'comments': [
            {'\$ref': 'Comment:324'}
          ]
        },
        'Author:1': {'id': '1', '__typename': 'Author', 'name': 'Paul'},
        'Comment:324': {
          'id': '324',
          '__typename': 'Comment',
          'commenter': {'\$ref': 'Author:2'}
        },
        'Author:2': {'id': '2', '__typename': 'Author', 'name': 'Nicole'}
      };

      final typePolicies = {
        'Post': TypePolicy(
          keyFields: {
            'id': true,
            'title': "I'm a string",
            'missing': false,
            'author': {
              'name': true,
              'missing': 3,
            },
          },
        )
      };

      test('Produces correct normalized object', () {
        final normalizedResult = <String, Map<String, dynamic>?>{};
        normalizeOperation(
          read: (dataId) => normalizedResult[dataId],
          write: (dataId, value) => normalizedResult[dataId] = value,
          document: query,
          data: sharedResponse,
          typePolicies: typePolicies,
        );

        expect(
          normalizedResult,
          equals(normalizedMap),
        );
      });

      test('Produces correct nested data object', () {
        expect(
          denormalizeOperation(
            document: query,
            read: (dataId) => normalizedMap[dataId],
            typePolicies: typePolicies,
          ),
          equals(sharedResponse),
        );
      });
    });

    group('with missing keyFields', () {
      final normalizedMap = {
        'Query': {
          '__typename': 'Query',
          'posts': [
            {
              'id': '123',
              '__typename': 'Post',
              'author': {'\$ref': 'Author:1'},
              'title': 'My awesome blog post',
              'comments': [
                {'\$ref': 'Comment:324'}
              ]
            }
          ]
        },
        'Author:1': {'id': '1', '__typename': 'Author', 'name': 'Paul'},
        'Comment:324': {
          'id': '324',
          '__typename': 'Comment',
          'commenter': {'\$ref': 'Author:2'}
        },
        'Author:2': {'id': '2', '__typename': 'Author', 'name': 'Nicole'}
      };

      final typePolicies = {
        'Post': TypePolicy(
          keyFields: {
            'id': true,
            'title': true,
            'author': {
              'missing': true,
            },
          },
        )
      };

      test('Produces correct normalized object', () {
        final normalizedResult = <String, Map<String, dynamic>?>{};
        normalizeOperation(
          read: (dataId) => normalizedResult[dataId],
          write: (dataId, value) => normalizedResult[dataId] = value,
          document: query,
          data: sharedResponse,
          typePolicies: typePolicies,
        );

        expect(
          normalizedResult,
          equals(normalizedMap),
        );
      });

      test('Produces correct nested data object', () {
        expect(
          denormalizeOperation(
            document: query,
            read: (dataId) => normalizedMap[dataId],
            typePolicies: typePolicies,
          ),
          equals(sharedResponse),
        );
      });
    });

    group('with empty keyFields', () {
      final normalizedMap = {
        'Query': {
          '__typename': 'Query',
          'posts': [
            {
              'id': '123',
              '__typename': 'Post',
              'author': {'\$ref': 'Author:1'},
              'title': 'My awesome blog post',
              'comments': [
                {'\$ref': 'Comment:324'}
              ]
            }
          ]
        },
        'Author:1': {'id': '1', '__typename': 'Author', 'name': 'Paul'},
        'Comment:324': {
          'id': '324',
          '__typename': 'Comment',
          'commenter': {'\$ref': 'Author:2'}
        },
        'Author:2': {'id': '2', '__typename': 'Author', 'name': 'Nicole'}
      };

      final typePolicies = {
        'Post': TypePolicy(
          keyFields: {},
        )
      };

      test('Produces correct normalized object', () {
        final normalizedResult = <String, Map<String, dynamic>?>{};
        normalizeOperation(
          read: (dataId) => normalizedResult[dataId],
          write: (dataId, value) => normalizedResult[dataId] = value,
          document: query,
          data: sharedResponse,
          typePolicies: typePolicies,
        );

        expect(
          normalizedResult,
          equals(normalizedMap),
        );
      });

      test('Produces correct nested data object', () {
        expect(
          denormalizeOperation(
            document: query,
            read: (dataId) => normalizedMap[dataId],
            typePolicies: typePolicies,
          ),
          equals(sharedResponse),
        );
      });
    });
  });
}
