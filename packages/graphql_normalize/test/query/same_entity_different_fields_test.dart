import 'package:test/test.dart';
import 'package:gql/language.dart';

import 'package:graphql_normalize/normalize.dart';

void main() {
  group('Same Entity Different Fields', () {
    final query = parseString('''
      query TestQuery {
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
              age
            }
          }
        }
      }
    ''');

    final data = {
      'posts': [
        {
          'id': '123',
          '__typename': 'Post',
          'author': {'id': '1', '__typename': 'Author', 'name': 'Paul'},
          'title': 'My awesome blog post',
          'comments': [
            {
              'id': '324',
              '__typename': 'Comment',
              'commenter': {
                'id': '1',
                '__typename': 'Author',
                'name': 'Paul',
                'age': 33
              }
            }
          ]
        }
      ]
    };

    final normalizedMap = {
      'Query': {
        'posts': [
          {'\$ref': 'Post:123'}
        ]
      },
      'Post:123': {
        'id': '123',
        '__typename': 'Post',
        'author': {'\$ref': 'Author:1'},
        'title': 'My awesome blog post',
        'comments': [
          {'\$ref': 'Comment:324'}
        ]
      },
      'Comment:324': {
        'id': '324',
        '__typename': 'Comment',
        'commenter': {'\$ref': 'Author:1'}
      },
      'Author:1': {'id': '1', '__typename': 'Author', 'name': 'Paul', 'age': 33}
    };

    test('Produces correct normalized object', () {
      final normalizedResult = <String, Map<String, dynamic>?>{};
      normalizeOperation(
        read: (dataId) => normalizedResult[dataId],
        write: (dataId, value) => normalizedResult[dataId] = value,
        document: query,
        data: data,
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
          ),
          equals(data));
    });
  });
}
