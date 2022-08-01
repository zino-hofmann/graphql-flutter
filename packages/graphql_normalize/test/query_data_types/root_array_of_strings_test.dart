import 'package:test/test.dart';
import 'package:gql/language.dart';

import 'package:graphql_normalize/normalize.dart';

void main() {
  group('Root Array of Strings', () {
    final query = parseString('''
      query TestQuery {
        tags
      }
    ''');

    final data = {
      'tags': ['tag1', 'tag2', 'tag3']
    };

    final normalizedMap = {
      'Query': {
        'tags': ['tag1', 'tag2', 'tag3']
      }
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
        equals(data),
      );
    });
  });
}
