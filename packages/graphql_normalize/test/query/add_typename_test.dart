import 'package:test/test.dart';
import 'package:gql/language.dart';

import 'package:graphql_normalize/normalize.dart';
import '../shared_data.dart';

void main() {
  group(
    'Add Typename',
    () {
      test(
        'Simple query',
        () {
          final query = parseString('''
            query TestQuery {
              posts {
                id
                author {
                  id
                  name
                }
                title
                comments {
                  id
                  commenter {
                    id
                    name
                  }
                }
              }
            }
          ''');
          expect(
            denormalizeOperation(
              document: query,
              read: (dataId) => sharedNormalizedMap[dataId],
              addTypename: true,
            ),
            equals(sharedResponse),
          );

          final normalizedResult = <String, Map<String, dynamic>?>{};
          normalizeOperation(
            read: (dataId) => normalizedResult[dataId],
            addTypename: true,
            document: query,
            data: sharedResponse,
            write: (dataId, value) => normalizedResult[dataId] = value,
          );

          expect(
            normalizedResult,
            equals(sharedNormalizedMap),
          );
        },
      );

      test(
        'Inline Fragments',
        () {
          final query = parseString('''
            query TestQuery {
              posts {
                id
                author {
                  ...on Author {
                    id
                    name
                  }
                }
                title
                comments {
                  id
                  commenter {
                    id
                    name
                  }
                }
              }
            }
          ''');
          expect(
            denormalizeOperation(
              document: query,
              read: (dataId) => sharedNormalizedMap[dataId],
              addTypename: true,
            ),
            equals(sharedResponse),
          );

          final normalizedResult = <String, Map<String, dynamic>?>{};
          normalizeOperation(
            read: (dataId) => normalizedResult[dataId],
            addTypename: true,
            document: query,
            data: sharedResponse,
            write: (dataId, value) => normalizedResult[dataId] = value,
          );

          expect(
            normalizedResult,
            equals(sharedNormalizedMap),
          );
        },
      );

      test(
        'Fragment Definition',
        () {
          final query = parseString('''
            query TestQuery {
              posts {
                id
                author {
                  id
                  name
                }
                title
                comments {
                  ...commentsFragment
                }
              }
            }
          
            fragment commentsFragment on Comment {
              id
              commenter {
                id
                name
              }
            }
          ''');
          expect(
            denormalizeOperation(
              document: query,
              read: (dataId) => sharedNormalizedMap[dataId],
              addTypename: true,
            ),
            equals(sharedResponse),
          );

          final normalizedResult = <String, Map<String, dynamic>?>{};
          normalizeOperation(
            read: (dataId) => normalizedResult[dataId],
            addTypename: true,
            document: query,
            data: sharedResponse,
            write: (dataId, value) => normalizedResult[dataId] = value,
          );

          expect(
            normalizedResult,
            equals(sharedNormalizedMap),
          );
        },
      );
    },
  );
}
