import 'dart:collection';

import 'package:test/test.dart';

import 'package:graphql/src/utilities/helpers.dart';

void main() {
  group('deeplyMergeLeft', () {
    test('shallow', () {
      expect(
        deeplyMergeLeft([
          {'keyA': 'a1'},
          {'keyA': 'a2', 'keyB': 'b2'},
          {'keyB': 'b3'}
        ]),
        equals({'keyA': 'a2', 'keyB': 'b3'}),
      );
    });

    test('deep', () {
      expect(
        deeplyMergeLeft([
          <String, dynamic>{
            'keyA': 'a1',
            'keyB': {
              'keyC': {'keyD': 'd1'}
            }
          },
          <String, dynamic>{
            'keyA': 'a2',
            'keyB': {
              'keyC': {'keyD': 'd2'}
            }
          },
        ]),
        equals({
          'keyA': 'a2',
          'keyB': {
            'keyC': {'keyD': 'd2'}
          }
        }),
      );
    });

    test('deep hashmaps are merged', () {
      expect(
        deeplyMergeLeft([
          HashMap<String, dynamic>.from({
            'keyA': 'a1',
            'keyB': {
              'keyC':
                  HashMap<String, dynamic>.from(<String, dynamic>{'keyD': 'd1'})
            }
          }),
          {
            'keyA': 'a2',
            'keyB': {
              'keyC':
                  HashMap<String, dynamic>.from(<String, dynamic>{'keyD': 'd2'})
            }
          },
        ]),
        equals({
          'keyA': 'a2',
          'keyB': {
            'keyC': {'keyD': 'd2'}
          }
        }),
      );
    });
  });
}
