import 'package:test/test.dart';
import 'package:gql/language.dart';

import 'package:graphql_normalize/normalize.dart';
import '../shared_data.dart';

void main() {
  group('Multiple Operations', () {
    test('With operationName', () {
      final query = parseString('''
        query FirstQuery {
          author {
            id
          }
        }
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
          operationName: 'TestQuery',
          addTypename: true,
        ),
        equals(sharedResponse),
      );

      final normalizedResult = <String, Map<String, dynamic>?>{};
      normalizeOperation(
        read: (dataId) => normalizedResult[dataId],
        addTypename: true,
        write: (dataId, value) => normalizedResult[dataId] = value,
        document: query,
        data: sharedResponse,
        operationName: 'TestQuery',
      );

      expect(
        normalizedResult,
        equals(sharedNormalizedMap),
      );
    });

    test('Without operationName', () {
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

        query FirstQuery {
          author {
            id
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
        write: (dataId, value) => normalizedResult[dataId] = value,
        document: query,
        data: sharedResponse,
        operationName: 'TestQuery',
      );

      expect(
        normalizedResult,
        equals(sharedNormalizedMap),
      );
    });
  });
}
