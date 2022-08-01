import 'package:test/test.dart';
import 'package:gql/language.dart';

import 'package:graphql_normalize/normalize.dart';
import '../shared_data.dart';

void main() {
  group('Alias', () {
    final query = parseString('''
      query TestQuery {
        __typename
        posts {
          id
          __typename
          olle: author {
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

    final data = {
      '__typename': 'Query',
      'posts': [
        {
          'id': '123',
          '__typename': 'Post',
          'olle': {'id': '1', '__typename': 'Author', 'name': 'Paul'},
          'title': 'My awesome blog post',
          'comments': [
            {
              'id': '324',
              '__typename': 'Comment',
              'commenter': {'id': '2', '__typename': 'Author', 'name': 'Nicole'}
            }
          ]
        }
      ]
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
        equals(sharedNormalizedMap),
      );
    });

    test('Produces correct nested data object', () {
      expect(
        denormalizeOperation(
          document: query,
          read: (dataId) => sharedNormalizedMap[dataId],
        ),
        equals(data),
      );
    });
  });
}
