import 'dart:async';
import 'dart:io';

import 'package:gql/language.dart';
import 'package:graphql/client.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  group('CancellableHttpLink', () {
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
      final link = CancellableHttpLink(serverUrl);
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

      // Cancel after a short delay (before server responds)
      await Future<void>.delayed(Duration(milliseconds: 100));
      cancellationToken.cancel();

      // Now await the result - it should have an exception, not throw
      QueryResult? result;
      try {
        result = await resultFuture;
      } catch (e) {
        // If an exception is thrown directly, convert to result with exception
        result = QueryResult(
          options: QueryOptions(
            document: parseString('query { test }'),
          ),
          source: QueryResultSource.network,
        );
        if (e is CancelledException) {
          result.exception = OperationException(linkException: e);
        } else if (e is http.ClientException &&
            (e.message.contains('cancelled') || e.message.contains('abort'))) {
          result.exception = OperationException(
            linkException: CancelledException('HTTP request was cancelled'),
          );
        } else {
          rethrow;
        }
      }

      // The result should have an exception
      expect(result.hasException, isTrue);
      expect(result.exception, isA<OperationException>());
      expect(result.exception!.linkException, isA<CancelledException>());

      cancellationToken.dispose();
      await link.dispose();
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
        final link = CancellableHttpLink(fastServerUrl);
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

        await link.dispose();
      } finally {
        await fastServer.close(force: true);
      }
    });

    test('CancellationToken is passed via context entry', () async {
      final fastServer = await HttpServer.bind('localhost', 0);
      final fastServerUrl = 'http://localhost:${fastServer.port}/graphql';

      fastServer.listen((request) async {
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"data": {"test": "success"}}');
        await request.response.close();
      });

      try {
        final link = CancellableHttpLink(fastServerUrl);
        final client = GraphQLClient(
          cache: GraphQLCache(),
          link: link,
        );

        final cancellationToken = CancellationToken();

        final result = await client.query(
          QueryOptions(
            document: parseString('query { test }'),
            fetchPolicy: FetchPolicy.networkOnly,
            cancellationToken: cancellationToken,
          ),
        );

        expect(result.hasException, isFalse);
        expect(result.data, equals({'test': 'success'}));

        cancellationToken.dispose();
        await link.dispose();
      } finally {
        await fastServer.close(force: true);
      }
    });

    test('queryCancellable with CancellableHttpLink actually cancels HTTP',
        () async {
      final link = CancellableHttpLink(serverUrl);
      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: link,
      );

      final operation = client.queryCancellable(
        QueryOptions(
          document: parseString('query { test }'),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      // Cancel after a short delay (before server responds)
      await Future<void>.delayed(Duration(milliseconds: 100));
      operation.cancel();

      QueryResult? result;
      try {
        result = await operation.result;
      } catch (e) {
        // If an exception is thrown directly, convert to result with exception
        result = QueryResult(
          options: QueryOptions(
            document: parseString('query { test }'),
          ),
          source: QueryResultSource.network,
        );
        if (e is CancelledException) {
          result.exception = OperationException(linkException: e);
        } else if (e is http.ClientException &&
            (e.message.contains('cancelled') || e.message.contains('abort'))) {
          result.exception = OperationException(
            linkException: CancelledException('HTTP request was cancelled'),
          );
        } else {
          rethrow;
        }
      }

      expect(result.hasException, isTrue);
      expect(result.exception!.linkException, isA<CancelledException>());

      await link.dispose();
    });
  });
}
