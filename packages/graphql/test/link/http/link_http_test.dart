import "dart:async";
import "dart:convert";

import 'package:gql/language.dart';
import 'package:graphql/client.dart';
import 'package:graphql/internal.dart';
import 'package:graphql/src/link/http/link_http.dart';
import 'package:graphql/src/link/link.dart';
import 'package:graphql/src/link/operation.dart';
import "package:http/http.dart" as http;
import 'package:http_parser/http_parser.dart';
import "package:mockito/mockito.dart";
import "package:test/test.dart";

class MockClient extends Mock implements http.Client {}

void main() {
  group('HTTP link', () {
    MockClient client;
    Operation query;
    Operation subscription;
    HttpLink link;

    setUp(() {
      client = MockClient();
      query = Operation(
        documentNode: parseString('query Operation {}'),
        operationName: 'Operation',
      );
      subscription = Operation(
        documentNode: parseString('subscription Operation {}'),
        operationName: 'Operation',
      );
      link = HttpLink(
        uri: '/graphql-test',
        httpClient: client,
      );
    });

    test('exception on subscription', () {
      expect(
        () => execute(link: link, operation: subscription),
        throwsA(
          const TypeMatcher<Exception>(),
        ),
      );
    });

    test('forward on subscription', () {
      bool forwardCalled = false;

      final forwardLink = Link(
        request: (Operation op, [NextLink forward]) {
          forwardCalled = true;

          return null;
        },
      );
      expect(
        execute(
          link: link.concat(forwardLink),
          operation: subscription,
        ),
        null,
      );

      expect(
        forwardCalled,
        true,
      );
    });

    test('request', () async {
      when(
        client.send(any),
      ).thenAnswer(
        (_) => Future.value(
          http.StreamedResponse(
            Stream.fromIterable(
              [utf8.encode('{"data":{}}')],
            ),
            200,
          ),
        ),
      );

      await execute(
        link: link,
        operation: query,
      ).first;

      final http.Request captured = verify(
        client.send(captureAny),
      ).captured.single;

      expect(
        captured.url,
        Uri.parse('/graphql-test'),
      );
      expect(
        captured.method,
        'post',
      );
      expect(
        captured.headers,
        equals({
          'accept': '*/*',
          'content-type': 'application/json; charset=utf-8',
        }),
      );
      expect(
        captured.body,
        '{"operationName":"Operation","variables":{},"query":"query Operation {\\n  \\n}"}',
      );
    });

    test('request with link defaults', () async {
      link = HttpLink(
        uri: '/graphql-test',
        httpClient: client,
        includeExtensions: true,
        fetchOptions: {'option-1:default': 'option-value-1:default'},
        credentials: {'credential-1:default': 'credential-value-1:default'},
        headers: {'header-1:default': 'header-value-1:default'},
      );

      when(
        client.send(any),
      ).thenAnswer(
        (_) => Future.value(
          http.StreamedResponse(
            Stream.fromIterable(
              [utf8.encode('{"data":{}}')],
            ),
            200,
          ),
        ),
      );

      await execute(
        link: link,
        operation: query,
      ).first;

      final http.Request captured = verify(
        client.send(captureAny),
      ).captured.single;

      expect(
        captured.url,
        Uri.parse('/graphql-test'),
      );
      expect(
        captured.method,
        'post',
      );
      expect(
        captured.headers,
        equals({
          'accept': '*/*',
          'content-type': 'application/json; charset=utf-8',
          'header-1:default': 'header-value-1:default',
        }),
      );
      expect(
        captured.body,
        '{"operationName":"Operation","variables":{},"extensions":null,"query":"query Operation {\\n  \\n}"}',
      );
    });

    test('request with context', () async {
      when(
        client.send(any),
      ).thenAnswer(
        (_) => Future.value(
          http.StreamedResponse(
            Stream.fromIterable(
              [utf8.encode('{"data":{}}')],
            ),
            200,
          ),
        ),
      );

      query.setContext({
        'includeExtensions': true,
        'fetchOptions': {'option-1': 'option-value-1'},
        'credentials': {'credential-1': 'credential-value-1'},
        'headers': {'header-1': 'header-value-1'},
      });

      await execute(
        link: link,
        operation: query,
      ).first;

      final http.Request captured = verify(
        client.send(captureAny),
      ).captured.single;

      expect(
        captured.url,
        Uri.parse('/graphql-test'),
      );
      expect(
        captured.method,
        'post',
      );
      expect(
        captured.headers,
        equals({
          'accept': '*/*',
          'content-type': 'application/json; charset=utf-8',
          'header-1': 'header-value-1',
        }),
      );
      expect(
        captured.body,
        '{"operationName":"Operation","variables":{},"extensions":null,"query":"query Operation {\\n  \\n}"}',
      );
    });

    test('request with extensions', () async {
      when(
        client.send(any),
      ).thenAnswer(
        (_) => Future.value(
          http.StreamedResponse(
            Stream.fromIterable(
              [utf8.encode('{"data":{}}')],
            ),
            200,
          ),
        ),
      );

      final query = Operation(
        documentNode: parseString('{}'),
        extensions: {'extension-1': 'extension-value-1'},
      );
      query.setContext({
        'includeExtensions': true,
      });

      await execute(
        link: link,
        operation: query,
      ).first;

      final http.Request captured = verify(
        client.send(captureAny),
      ).captured.single;

      expect(
        captured.body,
        '{"operationName":null,"variables":{},"extensions":{"extension-1":"extension-value-1"},"query":"query {\\n  \\n}"}',
      );
    });

    test('successful data response', () async {
      when(
        client.send(any),
      ).thenAnswer(
        (_) => Future.value(
          http.StreamedResponse(
            Stream.fromIterable(
              [utf8.encode('{"data":{}}')],
            ),
            200,
          ),
        ),
      );

      final result = await execute(
        link: link,
        operation: query,
      ).first;

      expect(
        result.data,
        equals({}),
      );
      expect(
        result.errors,
        null,
      );
    });

    test('successful error response', () async {
      when(
        client.send(any),
      ).thenAnswer(
        (_) => Future.value(
          http.StreamedResponse(
            Stream.fromIterable(
              [utf8.encode('{"errors":[]}')],
            ),
            200,
          ),
        ),
      );

      final result = await execute(
        link: link,
        operation: query,
      ).first;

      expect(
        result.errors,
        equals([]),
      );
      expect(
        result.data,
        null,
      );
    });

    test('no data and errors suceessful response', () async {
      when(
        client.send(any),
      ).thenAnswer(
        (_) => Future.value(
          http.StreamedResponse(
            Stream.fromIterable(
              [utf8.encode('{}')],
            ),
            200,
          ),
        ),
      );

      Exception exception;

      try {
        await execute(
          link: link,
          operation: query,
        ).first;
      } on Exception catch (e) {
        exception = e;
      }

      expect(
        exception,
        const TypeMatcher<NetworkException>(),
      );

      expect(
        (exception as NetworkException).wrappedException,
        const TypeMatcher<http.ClientException>(),
      );

      expect(
        exception.toString(),
        'Failed to connect to /graphql-test: Invalid response body: {}',
      );
    });

    test('no data and errors failed response', () async {
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

      Exception exception;

      try {
        await execute(
          link: link,
          operation: query,
        ).first;
      } on Exception catch (e) {
        exception = e;
      }

      expect(
        exception,
        const TypeMatcher<NetworkException>(),
      );

      expect(
        (exception as NetworkException).wrappedException,
        const TypeMatcher<http.ClientException>(),
      );

      expect(
        exception.toString(),
        'Failed to connect to /graphql-test: Network Error: 400 {}',
      );
    });

    test('data on failed response', () async {
      when(
        client.send(any),
      ).thenAnswer(
        (_) => Future.value(
          http.StreamedResponse(
            Stream.fromIterable(
              [utf8.encode('{"data":{}}')],
            ),
            300,
          ),
        ),
      );

      final result = await execute(
        link: link,
        operation: query,
      ).first;

      expect(
        result.data,
        equals({}),
      );
      expect(
        result.errors,
        null,
      );
    });

    test('non-json response', () async {
      when(
        client.send(any),
      ).thenAnswer(
        (_) => Future.value(
          http.StreamedResponse(
            Stream.fromIterable(
              [utf8.encode('')],
            ),
            200,
          ),
        ),
      );

      Exception exception;

      try {
        await execute(
          link: link,
          operation: query,
        ).first;
      } on Exception catch (e) {
        exception = e;
      }

      expect(
        exception,
        const TypeMatcher<UnhandledFailureWrapper>(),
      );

      expect(
        (exception as UnhandledFailureWrapper).failure,
        const TypeMatcher<FormatException>(),
      );
    });

    test('request with multipart file', () async {
      when(
        client.send(any),
      ).thenAnswer(
        (_) => Future.value(
          http.StreamedResponse(
            Stream.fromIterable(
              [utf8.encode('{"data":{}}')],
            ),
            200,
          ),
        ),
      );

      final query = Operation(
        documentNode: parseString('{}'),
        variables: {
          'files': [
            http.MultipartFile.fromString(
              'field-1',
              'just plain text 1',
              filename: 'sample_upload1.txt',
              contentType: MediaType('text', 'plain'),
            ),
            http.MultipartFile.fromString(
              'field-2',
              'just plain text 2',
              filename: 'sample_upload2.txt',
              contentType: MediaType('text', 'plain'),
            ),
          ],
        },
      );

      await execute(
        link: link,
        operation: query,
      ).first;

      final http.MultipartRequest captured = verify(
        client.send(captureAny),
      ).captured.single;

      final req = await captured.finalize().bytesToString();

      expect(
        req
            .replaceAll(
              RegExp('--dart-http-boundary-.{51}'),
              '--dart-http-boundary-REPLACED',
            )
            .replaceAll(
              '\r\n',
              '\n',
            ),
        r'''--dart-http-boundary-REPLACED
content-disposition: form-data; name="operations"

{"operationName":null,"variables":{"files":[null,null]},"query":"query {\n  \n}"}
--dart-http-boundary-REPLACED
content-disposition: form-data; name="map"

{"0":["variables.files.0"],"1":["variables.files.1"]}
--dart-http-boundary-REPLACED
content-type: text/plain; charset=utf-8
content-disposition: form-data; name="0"; filename="sample_upload1.txt"

just plain text 1
--dart-http-boundary-REPLACED
content-type: text/plain; charset=utf-8
content-disposition: form-data; name="1"; filename="sample_upload2.txt"

just plain text 2
--dart-http-boundary-REPLACED--
''',
      );
    });
  });
}
