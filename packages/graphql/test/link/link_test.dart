import 'package:graphql/src/link/link.dart';
import 'package:graphql/src/link/operation.dart';
import 'package:test/test.dart';

void main() {
  group('link', () {
    test('multiple', () {
      String result = '';

      final link1 = Link(
        request: (Operation op, [NextLink forward]) {
          result += '1';
          return null;
        },
      );

      final link2 = Link(
        request: (Operation op, [NextLink forward]) {
          result += '2';
          return null;
        },
      );

      final link3 = Link(
        request: (Operation op, [NextLink forward]) {
          result += '3';
          return null;
        },
      );

      expect(
        execute(
          link: Link.from([link1, link2, link3]),
          operation: null,
        ),
        null,
      );

      expect(result, '123');
    });
  });
}
