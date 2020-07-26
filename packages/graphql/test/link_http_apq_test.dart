import "dart:async";
import "dart:convert";
import 'dart:io';

import 'package:gql/language.dart';
import 'package:graphql/client.dart';
import 'package:graphql/src/links/persisted_queries_link.dart';
import "package:http/http.dart" as http;
import "package:mockito/mockito.dart";
import "package:test/test.dart";

class MockClient extends Mock implements http.Client {}

Response getEmptyResponse() => Response().withContextEntry(
      HttpLinkResponseContext(
        headers: {},
        statusCode: 200,
      ),
    );

void main() {
  group('Automatic Persisted Queries link integrated with HttpLink', () {
    MockClient client;
    Operation query;
    Link link;
    Request request;

    setUp(() {
      client = MockClient();
      query = Operation(
        document: parseString('query Operation {}'),
        operationName: 'Operation',
      );
      request = Request(operation: query);
      link = PersistedQueriesLink(
        useGETForHashedQueries: true,
      ).concat(
        HttpLink(
          '/graphql-apq-test',
          httpClient: client,
        ),
      );
    });

    test('request persisted query', () async {
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

      await link.request(request).first;

      final http.Request captured = verify(
        client.send(captureAny),
      ).captured.single;

      final extensions =
          json.decode(captured.url.queryParameters['extensions']);

      expect(
        captured.url,
        Uri.parse(
            '/graphql-apq-test?operationName=Operation&variables=%7B%7D&extensions=%7B%22persistedQuery%22%3A%7B%22sha256Hash%22%3A%228c4ae5b728c7cd94514caf043b362244c226a39dc29517ddbfb9a827abd2faa5%22%2C%22version%22%3A1%7D%7D'),
      );
      expect(
        extensions['persistedQuery']['sha256Hash'],
        '8c4ae5b728c7cd94514caf043b362244c226a39dc29517ddbfb9a827abd2faa5',
      );
      expect(
        captured.method,
        'GET',
      );
      expect(
        captured.headers,
        equals({
          'Accept': '*/*',
          'Content-type': 'application/json',
        }),
      );
      expect(
        captured.body,
        '',
      );
    });

    test('handle "PERSISTED_QUERY_NOT_FOUND"', () async {
      when(
        client.send(any),
      )..thenAnswer(
          (inv) {
            http.Request request = inv.positionalArguments[0];
            return Future.value(
              http.StreamedResponse(
                Stream.fromIterable(
                  [
                    utf8.encode(request.method == 'GET'
                        ? '{"errors":[{"extensions": { "code": "PERSISTED_QUERY_NOT_FOUND" }, "message": "PersistedQueryNotFound" }]}'
                        : '{"data":{}}')
                  ],
                ),
                200,
              ),
            );
          },
        );

      final result = await link.request(request).first;

      final captured = verify(
        client.send(captureAny),
      ).captured.cast<http.Request>();

      final extensions = json.decode(
        captured.first.url.queryParameters['extensions'],
      );
      final postBody = json.decode(captured[1].body);

      expect(
        captured.length,
        2,
      );
      expect(
        captured.first.method,
        'GET',
      );
      expect(
        extensions['persistedQuery']['sha256Hash'],
        '8c4ae5b728c7cd94514caf043b362244c226a39dc29517ddbfb9a827abd2faa5',
      );
      expect(
        captured.first.url,
        Uri.parse(
            '/graphql-apq-test?operationName=Operation&variables=%7B%7D&extensions=%7B%22persistedQuery%22%3A%7B%22sha256Hash%22%3A%228c4ae5b728c7cd94514caf043b362244c226a39dc29517ddbfb9a827abd2faa5%22%2C%22version%22%3A1%7D%7D'),
      );
      expect(
        captured[1].method,
        'POST',
      );
      expect(
        postBody['extensions']['persistedQuery']['sha256Hash'],
        '8c4ae5b728c7cd94514caf043b362244c226a39dc29517ddbfb9a827abd2faa5',
      );
      expect(
        postBody.containsKey('query'),
        isTrue,
      );

      final HttpLinkResponseContext resp = result.context.entry();
      expect(
        resp.statusCode,
        200,
      );
    });

    test('handle server that does not support persisted queries', () async {
      when(
        client.send(any),
      )..thenAnswer(
          (inv) {
            http.Request request = inv.positionalArguments[0];
            return Future.value(
              http.StreamedResponse(
                Stream.fromIterable(
                  [
                    utf8.encode(request.method == 'GET'
                        ? '{"errors":[{"extensions": { "code": "PERSISTED_QUERY_NOT_SUPPORTED" }, "message": "PersistedQueryNotSupported" }]}'
                        : '{"data":{}}')
                  ],
                ),
                200,
              ),
            );
          },
        );

      final result = await link.request(request).first;

      final captured = List<http.Request>.from(verify(
        client.send(captureAny),
      ).captured);

      expect(
        captured.length,
        2,
      );

      final extensions =
          json.decode(captured.first.url.queryParameters['extensions']);
      final postBody = json.decode(captured[1].body);

      expect(
        captured.first.method,
        'GET',
      );
      expect(
        extensions['persistedQuery']['sha256Hash'],
        '8c4ae5b728c7cd94514caf043b362244c226a39dc29517ddbfb9a827abd2faa5',
      );
      expect(
        captured.first.url,
        Uri.parse(
            '/graphql-apq-test?operationName=Operation&variables=%7B%7D&extensions=%7B%22persistedQuery%22%3A%7B%22sha256Hash%22%3A%228c4ae5b728c7cd94514caf043b362244c226a39dc29517ddbfb9a827abd2faa5%22%2C%22version%22%3A1%7D%7D'),
      );
      expect(
        captured[1].method,
        'POST',
      );
      expect(
        postBody.containsKey('extensions'),
        isFalse,
      );
      expect(
        postBody.containsKey('query'),
        isTrue,
      );
      final HttpLinkResponseContext resp = result.context.entry();
      expect(
        resp.statusCode,
        200,
      );
    });

    test('unsubscribes correctly', () async {
      final link = Link.from([
        PersistedQueriesLink(),
        Link.function((request, [forward]) {
          return Stream.fromFuture(Future.delayed(
            Duration(milliseconds: 100),
            getEmptyResponse,
          ));
        })
      ]);

      StreamSubscription subscription = link.request(request).listen(
            (_) => fail('should not complete'),
            onError: (_) => fail('should not complete'),
            onDone: () => fail('should not complete'),
          );

      await Future.delayed(Duration(milliseconds: 10), () {
        subscription.cancel();
      });
    });

    test('supports loading the hash from other method', () async {
      final link = Link.from([
        PersistedQueriesLink(
          getQueryHash: (_) => 'custom_hashCode',
        ),
        HttpLink(
          '/graphql-apq-test',
          httpClient: client,
        ),
      ]);

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

      await link.request(request).first;

      final http.Request captured = verify(
        client.send(captureAny),
      ).captured.single;

      final extensions =
          json.decode(captured.url.queryParameters['extensions']);

      expect(
        captured.url,
        Uri.parse(
            '/graphql-apq-test?operationName=Operation&variables=%7B%7D&extensions=%7B%22persistedQuery%22%3A%7B%22sha256Hash%22%3A%22custom_hashCode%22%2C%22version%22%3A1%7D%7D'),
      );
      expect(
        extensions['persistedQuery']['sha256Hash'],
        'custom_hashCode',
      );
      expect(
        captured.method,
        'GET',
      );
    });

    test('errors if unable to hash query', () async {
      final link = Link.from([
        PersistedQueriesLink(getQueryHash: (_) {
          throw Exception('failed to hash query');
        }),
        Link.function((request, [forward]) {
          return Stream.value(getEmptyResponse());
        }),
      ]);

      expect(
        link.request(request).first,
        throwsException,
      );
    });

    test('supports a custom disable check function', () async {
      final link = Link.from([
        PersistedQueriesLink(
          disableOnError: (req, resp, [err]) => false,
        ),
        HttpLink(
          '/graphql-apq-test',
          httpClient: client,
        ),
      ]);

      when(
        client.send(any),
      )..thenAnswer(
          (inv) {
            http.Request request = inv.positionalArguments[0];
            return Future.value(
              http.StreamedResponse(
                Stream.fromIterable(
                  [
                    utf8.encode(request.method == 'GET'
                        ? '{"errors":[{"extensions": { "code": "PERSISTED_QUERY_NOT_FOUND" }, "message": "PersistedQueryNotFound" }]}'
                        : '{"data":{}}')
                  ],
                ),
                request.method == 'GET' ? 400 : 200,
              ),
            );
          },
        );

      final result = await link.request(request).first;

      final captured = List<http.Request>.from(verify(
        client.send(captureAny),
      ).captured);

      expect(
        captured.length,
        2,
      );
      expect(
        captured.first.method,
        'GET',
      );
      expect(
        captured.first.url,
        Uri.parse(
            '/graphql-apq-test?operationName=Operation&variables=%7B%7D&extensions=%7B%22persistedQuery%22%3A%7B%22sha256Hash%22%3A%228c4ae5b728c7cd94514caf043b362244c226a39dc29517ddbfb9a827abd2faa5%22%2C%22version%22%3A1%7D%7D'),
      );
      expect(
        captured[1].method,
        'POST',
      );
      final HttpLinkResponseContext resp = result.context.entry();
      expect(
        resp.statusCode,
        200,
      );
    });

    test('errors if no forward link is available', () async {
      expect(
        () => PersistedQueriesLink().request(request).first,
        throwsA(predicate((e) =>
            e.message ==
            'PersistedQueryLink cannot be the last link in the chain.')),
      );
    });

    test('errors if network requests fail', () async {
      final link = Link.from([
        PersistedQueriesLink(),
        Link.function((request, [forward]) {
          return Stream.error(
            NetworkException(
              uri: Uri.parse("/graphql-apq-test"),
              message: 'network error',
            ),
          );
        }),
      ]);

      expect(
        () => link.request(request).first,
        throwsException,
      );
    });
  });
}
