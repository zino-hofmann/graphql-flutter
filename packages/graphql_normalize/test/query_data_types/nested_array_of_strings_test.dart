import 'package:test/test.dart';
import 'package:gql/language.dart';

import 'package:graphql_normalize/normalize.dart';

void main() {
  group('Nested Array of Strings', () {
    final query = parseString('''
      query TestQuery {
        tagsArray
      }
    ''');

    final data = {
      'tagsArray': [
        ['tag1.1', 'tag1.2', 'tag1.3'],
        ['tag2.1', 'tag2.2', 'tag2.3'],
        ['tag3.1', 'tag3.2', 'tag3.3']
      ]
    };

    final normalizedMap = {
      'Query': {
        'tagsArray': [
          ['tag1.1', 'tag1.2', 'tag1.3'],
          ['tag2.1', 'tag2.2', 'tag2.3'],
          ['tag3.1', 'tag3.2', 'tag3.3']
        ]
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
          equals(data));
    });
  });
}
