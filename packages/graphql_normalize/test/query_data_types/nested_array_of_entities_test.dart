import 'package:test/test.dart';
import 'package:gql/language.dart';

import 'package:graphql_normalize/normalize.dart';

void main() {
  group('Nested Array of Entities', () {
    final query = parseString('''
      query TestQuery {
        table {
          id
          __typename
          rows {
            id
            __typename
            value
          }
        }
      }
    ''');

    final data = {
      'table': {
        'id': 'T1',
        '__typename': 'Table',
        'rows': [
          [
            {'id': '1.1', '__typename': 'Cell', 'value': 'value 1.1'},
            {'id': '1.2', '__typename': 'Cell', 'value': 'value 1.2'}
          ],
          [
            {'id': '2.1', '__typename': 'Cell', 'value': 'value 2.1'},
            {'id': '2.2', '__typename': 'Cell', 'value': 'value 2.2'}
          ],
          [
            {'id': '3.1', '__typename': 'Cell', 'value': 'value 3.1'},
            {'id': '3.2', '__typename': 'Cell', 'value': 'value 3.2'}
          ]
        ]
      }
    };

    final normalizedMap = {
      'Query': {
        'table': {'\$ref': 'Table:T1'}
      },
      'Table:T1': {
        'id': 'T1',
        '__typename': 'Table',
        'rows': [
          [
            {'\$ref': 'Cell:1.1'},
            {'\$ref': 'Cell:1.2'}
          ],
          [
            {'\$ref': 'Cell:2.1'},
            {'\$ref': 'Cell:2.2'}
          ],
          [
            {'\$ref': 'Cell:3.1'},
            {'\$ref': 'Cell:3.2'}
          ]
        ]
      },
      'Cell:1.1': {'id': '1.1', '__typename': 'Cell', 'value': 'value 1.1'},
      'Cell:1.2': {'id': '1.2', '__typename': 'Cell', 'value': 'value 1.2'},
      'Cell:2.1': {'id': '2.1', '__typename': 'Cell', 'value': 'value 2.1'},
      'Cell:2.2': {'id': '2.2', '__typename': 'Cell', 'value': 'value 2.2'},
      'Cell:3.1': {'id': '3.1', '__typename': 'Cell', 'value': 'value 3.1'},
      'Cell:3.2': {'id': '3.2', '__typename': 'Cell', 'value': 'value 3.2'}
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
