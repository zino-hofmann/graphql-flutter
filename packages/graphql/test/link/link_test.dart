import 'package:graphql/client.dart';
import 'package:graphql/src/link/operation.dart';
import 'package:test/test.dart';

void main() {
  group('link', () {
    test('multiple', () {
      final link1 = Link(
        request: (Operation op, [NextLink forward]) {
          return null;
        },
      );

      final link2 = Link(
        request: (Operation op, [NextLink forward]) {
          return null;
        },
      );

      final link3 = Link(
        request: (Operation op, [NextLink forward]) {
          return null;
        },
      );

      final linksFrom = Link.from([link1, link2, link3]);

      final linksConcat = link1..concat(link2)..concat(link3);

      expect(linksFrom, linksConcat);
    });
  });
}
