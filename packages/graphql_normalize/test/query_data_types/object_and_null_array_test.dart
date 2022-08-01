import 'package:test/test.dart';
import 'package:gql/language.dart';

import 'package:graphql_normalize/normalize.dart';

void main() {
  group('Object and null array', () {
    final query = parseString('''
      query TestQuery(\$postIds: [ID!]!) {
        postsByIds(ids: \$postIds) {
          id
          __typename
          title
        }
      }
    ''');

    final variables = {
      'postIds': ['123', 'non-existent-id']
    };

    final data = {
      'postsByIds': [
        {'id': '123', '__typename': 'Post', 'title': 'My awesome blog post'},
        null
      ]
    };

    final normalizedMap = {
      'Query': {
        'postsByIds({"ids":["123","non-existent-id"]})': [
          {'\$ref': 'Post:123'},
          null
        ]
      },
      'Post:123': {
        'id': '123',
        '__typename': 'Post',
        'title': 'My awesome blog post'
      }
    };

    test('Produces correct normalized object', () {
      final normalizedResult = <String, Map<String, dynamic>?>{};
      normalizeOperation(
        read: (dataId) => normalizedResult[dataId],
        write: (dataId, value) => normalizedResult[dataId] = value,
        document: query,
        data: data,
        variables: variables,
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
          variables: variables,
        ),
        equals(data),
      );
    });
  });
}
