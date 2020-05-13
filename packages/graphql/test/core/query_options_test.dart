import 'package:gql/language.dart';
import 'package:graphql/client.dart';
import 'package:test/test.dart';

void main() {
  group('FetchMoreOptions', () {
    group('constructs', () {
      final dummyUpdateQuery = (previousResultData, fetchMoreResultData) {
        return null;
      };

      final document = 'query { foo }';
      final documentParsed = parseString(document);

      final documentNode = parseString('query { bar }');

      test('with documentNode', () {
        final options = FetchMoreOptions(
          documentNode: documentNode,
          updateQuery: dummyUpdateQuery,
        );
        expect(options.documentNode, equals(documentNode));
      });

      test('with document', () {
        final options = FetchMoreOptions(
          // ignore: deprecated_member_use_from_same_package
          document: document,
          updateQuery: dummyUpdateQuery,
        );
        expect(options.documentNode, equals(documentParsed));
      });

      test('with neither', () {
        final options = FetchMoreOptions(
          updateQuery: dummyUpdateQuery,
        );
        expect(options.documentNode, isNull);
      });
    });
  });
}
