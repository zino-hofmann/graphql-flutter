import 'package:test/test.dart';
import 'package:gql/language.dart';

import 'package:graphql_normalize/normalize.dart';

void main() {
  group(
    'Missing ID',
    () {
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
              __typename
              commenter {
                id
                __typename
                name
              }
            }
          }

          testNode {
            __typename
            nisse
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
                '__typename': 'Comment',
                'commenter': {
                  'id': '2',
                  '__typename': 'Author',
                  'name': 'Nicole'
                }
              },
              {
                '__typename': 'Comment',
                'commenter': {
                  'id': '2',
                  '__typename': 'Author',
                  'name': 'Nicole'
                }
              }
            ]
          }
        ],
        'testNode': {'__typename': 'olle', 'nisse': 'asd'}
      };

      final normalizedMap = {
        'Query': {
          'posts': [
            {'\$ref': 'Post:123'}
          ],
          'testNode': {'__typename': 'olle', 'nisse': 'asd'}
        },
        'Post:123': {
          'id': '123',
          '__typename': 'Post',
          'author': {'\$ref': 'Author:1'},
          'title': 'My awesome blog post',
          'comments': [
            {
              '__typename': 'Comment',
              'commenter': {'\$ref': 'Author:2'}
            },
            {
              '__typename': 'Comment',
              'commenter': {'\$ref': 'Author:2'}
            }
          ]
        },
        'Author:1': {'id': '1', '__typename': 'Author', 'name': 'Paul'},
        'Author:2': {'id': '2', '__typename': 'Author', 'name': 'Nicole'},
      };

      final normalizedResult = <String, Map<String, dynamic>?>{};
      normalizeOperation(
        read: (dataId) => normalizedResult[dataId],
        document: query,
        data: data,
        write: (dataId, value) => normalizedResult[dataId] = value,
      );

      test(
        'Produces correct normalized object',
        () {
          expect(
              normalizedResult,
              equals(
                normalizedMap,
              ));
        },
      );

      test(
        'Produces correct nested data object',
        () {
          expect(
            denormalizeOperation(
              document: query,
              read: (dataId) => normalizedMap[dataId],
            ),
            equals(data),
          );
        },
      );
    },
  );
}
