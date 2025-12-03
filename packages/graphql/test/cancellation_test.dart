import 'package:gql/language.dart';
import 'package:graphql/client.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  late MockLink link;
  late GraphQLClient client;

  setUp(() {
    link = MockLink();

    client = GraphQLClient(
      cache: getTestCache(),
      link: link,
    );
  });

  group('Cancellation', () {
    test('query can be cancelled with CancellationToken', () async {
      final cancellationToken = CancellationToken();

      when(link.request(any)).thenAnswer(
        (_) => Stream.fromFuture(
          Future.delayed(
            Duration(milliseconds: 500),
            () => Response(
              data: <String, dynamic>{'test': 'data'},
              response: {},
            ),
          ),
        ),
      );

      final resultFuture = client.query(
        QueryOptions(
          document: parseString('query { test }'),
          fetchPolicy: FetchPolicy.networkOnly,
          cancellationToken: cancellationToken,
        ),
      );

      // Cancel after a short delay
      await Future<void>.delayed(Duration(milliseconds: 10));
      cancellationToken.cancel();

      final result = await resultFuture;
      expect(result.hasException, isTrue);
      expect(result.exception, isA<OperationException>());
      expect(result.exception!.linkException, isA<CancelledException>());

      cancellationToken.dispose();
    });

    test('queryCancellable returns CancellableOperation', () async {
      when(link.request(any)).thenAnswer(
        (_) => Stream.fromFuture(
          Future.delayed(
            Duration(milliseconds: 500),
            () => Response(
              data: <String, dynamic>{'test': 'data'},
              response: {},
            ),
          ),
        ),
      );

      final operation = client.queryCancellable(
        QueryOptions(
          document: parseString('query { test }'),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      expect(operation, isA<CancellableOperation<QueryResult>>());
      expect(operation.cancellationToken, isA<CancellationToken>());

      // Cancel after a short delay
      await Future<void>.delayed(Duration(milliseconds: 10));
      operation.cancel();

      final result = await operation.result;
      expect(result.hasException, isTrue);
      expect(result.exception, isA<OperationException>());
      expect(result.exception!.linkException, isA<CancelledException>());
    });

    test('mutation can be cancelled with CancellationToken', () async {
      final cancellationToken = CancellationToken();

      when(link.request(any)).thenAnswer(
        (_) => Stream.fromFuture(
          Future.delayed(
            Duration(milliseconds: 500),
            () => Response(
              data: <String, dynamic>{
                'createItem': {'id': '1'}
              },
              response: {},
            ),
          ),
        ),
      );

      final resultFuture = client.mutate(
        MutationOptions(
          document: parseString('mutation { createItem { id } }'),
          cancellationToken: cancellationToken,
        ),
      );

      // Cancel after a short delay
      await Future<void>.delayed(Duration(milliseconds: 10));
      cancellationToken.cancel();

      final result = await resultFuture;
      expect(result.hasException, isTrue);
      expect(result.exception, isA<OperationException>());
      expect(result.exception!.linkException, isA<CancelledException>());

      cancellationToken.dispose();
    });

    test('mutateCancellable returns CancellableOperation', () async {
      when(link.request(any)).thenAnswer(
        (_) => Stream.fromFuture(
          Future.delayed(
            Duration(milliseconds: 500),
            () => Response(
              data: <String, dynamic>{
                'createItem': {'id': '1'}
              },
              response: {},
            ),
          ),
        ),
      );

      final operation = client.mutateCancellable(
        MutationOptions(
          document: parseString('mutation { createItem { id } }'),
        ),
      );

      expect(operation, isA<CancellableOperation<QueryResult>>());
      expect(operation.cancellationToken, isA<CancellationToken>());

      // Cancel after a short delay
      await Future<void>.delayed(Duration(milliseconds: 10));
      operation.cancel();

      final result = await operation.result;
      expect(result.hasException, isTrue);
      expect(result.exception, isA<OperationException>());
      expect(result.exception!.linkException, isA<CancelledException>());
    });

    test('completed query is not affected by late cancellation', () async {
      final cancellationToken = CancellationToken();

      when(link.request(any)).thenAnswer(
        (_) => Stream.fromIterable([
          Response(
            data: <String, dynamic>{'test': 'data'},
            response: {},
          ),
        ]),
      );

      final result = await client.query(
        QueryOptions(
          document: parseString('query { test }'),
          cancellationToken: cancellationToken,
        ),
      );

      // Cancel after completion should not affect the result
      cancellationToken.cancel();

      expect(result.data, equals({'test': 'data'}));
      expect(result.hasException, isFalse);

      cancellationToken.dispose();
    });

    test('CancellationToken.isCancelled returns correct state', () {
      final token = CancellationToken();

      expect(token.isCancelled, isFalse);

      token.cancel();

      expect(token.isCancelled, isTrue);

      token.dispose();
    });

    test('cancelling already cancelled token has no effect', () {
      final token = CancellationToken();

      token.cancel();
      expect(token.isCancelled, isTrue);

      // Should not throw
      token.cancel();
      expect(token.isCancelled, isTrue);

      token.dispose();
    });
  });
}
