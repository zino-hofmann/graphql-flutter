import 'dart:async';
import 'dart:io';

import 'package:gql/language.dart';
import 'package:graphql/client.dart';
import 'package:test/test.dart';

void main() {
  group('HttpLink Cancellation', () {
    late HttpServer server;
    late String serverUrl;

    setUp(() async {
      // Create a simple HTTP server that delays response
      server = await HttpServer.bind('localhost', 0);
      serverUrl = 'http://localhost:${server.port}/graphql';

      server.listen((request) async {
        // Wait for 2 seconds before responding
        await Future<void>.delayed(Duration(seconds: 2));

        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"data": {"test": "data"}}');
        await request.response.close();
      });
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('cancelling request should abort the HTTP connection', () async {
      final link = HttpLink(serverUrl);
      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: link,
      );

      final cancellationToken = CancellationToken();

      // Start the query (don't await yet)
      final resultFuture = client.query(
        QueryOptions(
          document: parseString('query { test }'),
          fetchPolicy: FetchPolicy.networkOnly,
          cancellationToken: cancellationToken,
        ),
      );

      // Cancel after a short delay (before server responds - server delays 2 seconds)
      await Future<void>.delayed(Duration(milliseconds: 100));
      cancellationToken.cancel();

      // Now await the result
      final result = await resultFuture;

      // The result should have an exception
      expect(result.hasException, isTrue);
      expect(result.exception, isA<OperationException>());
      // The linkException should be a CancelledException
      expect(result.exception!.linkException, isA<CancelledException>());

      cancellationToken.dispose();
    });

    test('request completes normally without cancellation', () async {
      // Create a fast server for this test
      final fastServer = await HttpServer.bind('localhost', 0);
      final fastServerUrl = 'http://localhost:${fastServer.port}/graphql';

      fastServer.listen((request) async {
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"data": {"test": "success"}}');
        await request.response.close();
      });

      try {
        final link = HttpLink(fastServerUrl);
        final client = GraphQLClient(
          cache: GraphQLCache(),
          link: link,
        );

        final result = await client.query(
          QueryOptions(
            document: parseString('query { test }'),
            fetchPolicy: FetchPolicy.networkOnly,
          ),
        );

        expect(result.hasException, isFalse);
        expect(result.data, equals({'test': 'success'}));
      } finally {
        await fastServer.close(force: true);
      }
    });

    test('CancellationContextEntry is passed to link', () async {
      bool contextEntryFound = false;

      final testLink = Link.function((request, [forward]) async* {
        final entry = request.context.entry<CancellationContextEntry>();
        contextEntryFound = entry != null;

        yield Response(
          data: <String, dynamic>{'test': 'data'},
          response: {},
        );
      });

      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: testLink,
      );

      final cancellationToken = CancellationToken();

      await client.query(
        QueryOptions(
          document: parseString('query { test }'),
          fetchPolicy: FetchPolicy.networkOnly,
          cancellationToken: cancellationToken,
        ),
      );

      expect(contextEntryFound, isTrue);

      cancellationToken.dispose();
    });
  });
}
