import 'package:test/test.dart';
import 'package:gql/language.dart';

import 'package:graphql_normalize/normalize.dart';

void main() {
  group('Same Object with less fields in the Same Operation', () {
    final query = parseString('''
      query TestQuery {
        post {
          id
          __typename
          title
        }
        samePostWithLessFields {
          id
          __typename
        }
      }
    ''');

    final data = {
      'post': {
        'id': '123',
        '__typename': 'Post',
        'title': 'My awesome blog post',
      },
      'samePostWithLessFields': {
        '__typename': 'Post',
        'id': '123',
      },
    };

    final normalizedMap = {
      'Query': {
        'post': {'\$ref': 'Post:123'},
        'samePostWithLessFields': {'\$ref': 'Post:123'},
      },
      'Post:123': {
        'id': '123',
        '__typename': 'Post',
        'title': 'My awesome blog post',
      }
    };

    test('Doesn\'t lose fields', () {
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
  });
}
