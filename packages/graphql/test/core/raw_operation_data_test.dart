import 'package:gql/language.dart';
import 'package:graphql/src/core/raw_operation_data.dart';
import 'package:test/test.dart';

void main() {
  group('operation name', () {
    group('single operation', () {
      test('query without name', () {
        final opData = RawOperationData(
          documentNode: parseString('query {}'),
        );

        expect(opData.operationName, null);
      });

      test('query with explicit name', () {
        final opData = RawOperationData(
          documentNode: parseString('query Operation {}'),
          operationName: 'Operation',
        );

        expect(opData.operationName, 'Operation');
      });

      test('mutation with explicit name', () {
        final opData = RawOperationData(
          documentNode: parseString('mutation Operation {}'),
          operationName: 'Operation',
        );

        expect(opData.operationName, 'Operation');
      });

      test('subscription with explicit name', () {
        final opData = RawOperationData(
          documentNode: parseString('subscription Operation {}'),
          operationName: 'Operation',
        );

        expect(opData.operationName, 'Operation');
      });

      test('query with implicit name', () {
        final opData = RawOperationData(
          documentNode: parseString('query Operation {}'),
        );

        expect(opData.operationName, 'Operation');
      });

      test('mutation with implicit name', () {
        final opData = RawOperationData(
          documentNode: parseString('mutation Operation {}'),
        );

        expect(opData.operationName, 'Operation');
      });

      test('subscription with implicit name', () {
        final opData = RawOperationData(
          documentNode: parseString('subscription Operation {}'),
        );

        expect(opData.operationName, 'Operation');
      });
    });

    group('multiple operations', () {
      const document = r'''
        query OperationQ {}
        mutation OperationM {}
        subscription OperationS {}
      ''';

      test('query with explicit name', () {
        final opData = RawOperationData(
          documentNode: parseString(document),
          operationName: 'OperationQ',
        );

        expect(opData.operationName, 'OperationQ');
      });

      test('mutation with explicit name', () {
        final opData = RawOperationData(
          documentNode: parseString(document),
          operationName: 'OperationM',
        );

        expect(opData.operationName, 'OperationM');
      });

      test('subscription with explicit name', () {
        final opData = RawOperationData(
          documentNode: parseString(document),
          operationName: 'OperationS',
        );

        expect(opData.operationName, 'OperationS');
      });

      test('query with implicit name', () {
        final opData = RawOperationData(
          documentNode: parseString(document),
        );

        expect(opData.operationName, 'OperationS');
      });

      test('mutation with implicit name', () {
        final opData = RawOperationData(
          documentNode: parseString(document),
        );

        expect(opData.operationName, 'OperationS');
      });

      test('subscription with implicit name', () {
        final opData = RawOperationData(
          documentNode: parseString(document),
        );

        expect(opData.operationName, 'OperationS');
      });
    });
  });
}
