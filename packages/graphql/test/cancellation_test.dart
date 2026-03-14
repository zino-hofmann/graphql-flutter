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

  group('CancellationToken', () {
    test('starts in non-cancelled state', () {
      final token = CancellationToken();
      expect(token.isCancelled, isFalse);
      token.dispose();
    });

    test('cancel() sets isCancelled to true', () {
      final token = CancellationToken();
      token.cancel();
      expect(token.isCancelled, isTrue);
      token.dispose();
    });

    test('calling cancel() multiple times has no effect', () {
      final token = CancellationToken();
      int cancelCount = 0;
      token.onCancel.listen((_) => cancelCount++);

      token.cancel();
      token.cancel();

      expect(token.isCancelled, isTrue);
      // Give the stream time to deliver
      Future<void>.delayed(Duration(milliseconds: 10)).then((_) {
        expect(cancelCount, equals(1));
        token.dispose();
      });
    });

    test('onCancel stream emits when cancelled', () async {
      final token = CancellationToken();
      final future = token.onCancel.first;
      token.cancel();
      await future; // should complete without timeout
      token.dispose();
    });
  });

  group('CancelledException', () {
    test('is a LinkException', () {
      final exception = CancelledException('test message');
      expect(exception, isA<LinkException>());
    });

    test('toString contains message', () {
      final exception = CancelledException('Operation was cancelled');
      expect(exception.toString(), contains('Operation was cancelled'));
    });
  });

  group('Query cancellation', () {
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

      // Cancel before the response arrives
      await Future<void>.delayed(Duration(milliseconds: 10));
      cancellationToken.cancel();

      final result = await resultFuture;
      expect(result.hasException, isTrue);
      expect(result.exception, isA<OperationException>());
      expect(result.exception!.linkException, isA<CancelledException>());

      cancellationToken.dispose();
    });

    test('already-cancelled token causes immediate cancellation', () async {
      final cancellationToken = CancellationToken();
      cancellationToken.cancel(); // cancel before starting

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
          fetchPolicy: FetchPolicy.networkOnly,
          cancellationToken: cancellationToken,
        ),
      );

      expect(result.hasException, isTrue);
      expect(result.exception!.linkException, isA<CancelledException>());

      cancellationToken.dispose();
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

      // Cancel after completion
      cancellationToken.cancel();

      expect(result.data, equals({'test': 'data'}));
      expect(result.hasException, isFalse);

      cancellationToken.dispose();
    });
  });

  group('Mutation cancellation', () {
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

      await Future<void>.delayed(Duration(milliseconds: 10));
      cancellationToken.cancel();

      final result = await resultFuture;
      expect(result.hasException, isTrue);
      expect(result.exception!.linkException, isA<CancelledException>());

      cancellationToken.dispose();
    });
  });

  group('queryCancellable convenience method', () {
    test('returns CancellableOperation with cancel capability', () async {
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

      await Future<void>.delayed(Duration(milliseconds: 10));
      operation.cancel();

      final result = await operation.result;
      expect(result.hasException, isTrue);
      expect(result.exception!.linkException, isA<CancelledException>());
    });

    test('successful query through CancellableOperation', () async {
      when(link.request(any)).thenAnswer(
        (_) => Stream.fromIterable([
          Response(
            data: <String, dynamic>{'test': 'success'},
            response: {},
          ),
        ]),
      );

      final operation = client.queryCancellable(
        QueryOptions(
          document: parseString('query { test }'),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      final result = await operation.result;
      expect(result.hasException, isFalse);
      expect(result.data, equals({'test': 'success'}));
    });
  });

  group('mutateCancellable convenience method', () {
    test('returns CancellableOperation with cancel capability', () async {
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

      await Future<void>.delayed(Duration(milliseconds: 10));
      operation.cancel();

      final result = await operation.result;
      expect(result.hasException, isTrue);
      expect(result.exception!.linkException, isA<CancelledException>());
    });
  });
}
