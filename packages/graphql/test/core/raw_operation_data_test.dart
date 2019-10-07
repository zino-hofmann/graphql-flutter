import 'package:graphql/src/core/raw_operation_data.dart';
import 'package:test/test.dart';

void main() {
  group('operation name', () {
    group('single operation', () {
      test('query without name', () {
        final opData = RawOperationData(
          document: 'query {}',
        );

        expect(opData.operationName, null);
      });

      test('query with explicit name', () {
        final opData = RawOperationData(
          document: 'query Operation {}',
          operationName: 'Operation',
        );

        expect(opData.operationName, 'Operation');
      });

      test('mutation with explicit name', () {
        final opData = RawOperationData(
          document: 'mutation Operation {}',
          operationName: 'Operation',
        );

        expect(opData.operationName, 'Operation');
      });

      test('subscription with explicit name', () {
        final opData = RawOperationData(
          document: 'subscription Operation {}',
          operationName: 'Operation',
        );

        expect(opData.operationName, 'Operation');
      });

      test('query with implicit name', () {
        final opData = RawOperationData(
          document: 'query Operation {}',
        );

        expect(opData.operationName, 'Operation');
      });

      test('mutation with implicit name', () {
        final opData = RawOperationData(
          document: 'mutation Operation {}',
        );

        expect(opData.operationName, 'Operation');
      });

      test('subscription with implicit name', () {
        final opData = RawOperationData(
          document: 'subscription Operation {}',
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
          document: document,
          operationName: 'OperationQ',
        );

        expect(opData.operationName, 'OperationQ');
      });

      test('mutation with explicit name', () {
        final opData = RawOperationData(
          document: document,
          operationName: 'OperationM',
        );

        expect(opData.operationName, 'OperationM');
      });

      test('subscription with explicit name', () {
        final opData = RawOperationData(
          document: document,
          operationName: 'OperationS',
        );

        expect(opData.operationName, 'OperationS');
      });

      test('query with implicit name', () {
        final opData = RawOperationData(
          document: document,
        );

        expect(opData.operationName, 'OperationS');
      });

      test('mutation with implicit name', () {
        final opData = RawOperationData(
          document: document,
        );

        expect(opData.operationName, 'OperationS');
      });

      test('subscription with implicit name', () {
        final opData = RawOperationData(
          document: document,
        );

        expect(opData.operationName, 'OperationS');
      });
    });
  });
}
