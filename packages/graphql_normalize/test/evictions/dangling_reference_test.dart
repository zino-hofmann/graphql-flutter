import 'package:test/test.dart';
import 'package:gql/language.dart';

import 'package:graphql_normalize/normalize.dart';
import '../shared_data.dart';

void main() {
  group('Dangling references', () {
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

    final normalizedMap = {
      'Query': {
        '__typename': 'Query',
        'posts': [
          {'\$ref': 'Post:123'},
          {'\$ref': 'Post:456'},
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
      'Author:1': {
        'id': '1',
        '__typename': 'Author',
        'name': 'Paul',
      },
      'Comment:324': {
        'id': '324',
        '__typename': 'Comment',
        'commenter': {'\$ref': 'Author:2'},
      },
      'Author:2': {
        'id': '2',
        '__typename': 'Author',
        'name': 'Nicole',
      }
    };

    test('can filter out dangling references', () {
      expect(
          denormalizeOperation(
            document: query,
            read: (dataId) => normalizedMap[dataId],
          ),
          equals(sharedResponse));
    });
  });
}
