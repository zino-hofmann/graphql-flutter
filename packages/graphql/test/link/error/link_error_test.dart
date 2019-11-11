import "dart:async";
import "dart:convert";

import 'package:gql/language.dart';
import 'package:graphql/src/exceptions/exceptions.dart';
import 'package:graphql/src/link/error/link_error.dart';
import 'package:graphql/src/link/http/link_http.dart';
import 'package:graphql/src/link/link.dart';
import 'package:graphql/src/link/operation.dart';
import "package:http/http.dart" as http;
import "package:mockito/mockito.dart";
import "package:test/test.dart";

class MockClient extends Mock implements http.Client {}

void main() {
  group('error link', () {
    MockClient client;
    Operation query;
    HttpLink httpLink;

    setUp(() {
      client = MockClient();
      query = Operation(
        documentNode: parseString('query Operation {}'),
        operationName: 'Operation',
      );
      httpLink = HttpLink(
        uri: '/graphql-test',
        httpClient: client,
      );
    });

    test('network error', () async {
      bool called = false;

      when(
        client.send(any),
      ).thenAnswer(
        (_) => Future.value(
          http.StreamedResponse(
            Stream.fromIterable(
              [utf8.encode('{}')],
            ),
            400,
          ),
        ),
      );

      final errorLink = ErrorLink(errorHandler: (response) {
        if (response.exception.clientException != null) {
          called = true;
        }
      });

      Exception exception;

      try {
        await execute(
          link: errorLink.concat(httpLink),
          operation: query,
        ).first;
      } on Exception catch (e) {
        exception = e;
      }

      expect(
        exception,
        const TypeMatcher<ClientException>(),
      );
      expect(
        called,
        true,
      );
    });

    test('graphql error', () async {
      bool called = false;

      when(
        client.send(any),
      ).thenAnswer(
        (_) => Future.value(
          http.StreamedResponse(
            Stream.fromIterable(
              [utf8.encode('{"errors":[{"message":"error"}]}')],
            ),
            200,
          ),
        ),
      );

      final errorLink = ErrorLink(errorHandler: (response) {
        if (response.exception.graphqlErrors != null) {
          called = true;
        }
      });

      await execute(
        link: errorLink.concat(httpLink),
        operation: query,
      ).first;

      expect(
        called,
        true,
      );
    });
  });
}
