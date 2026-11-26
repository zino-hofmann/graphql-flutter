import 'dart:async';

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

  group('QueryManager', () {
    test("Can refetch", () {
      final response = Response(
        data: <String, dynamic>{
          'fetchPerson': null,
        },
        response: {},
      );
      when(
        link.request(any),
      ).thenAnswer(
        (_) => Stream.fromIterable(
          [response],
        ),
      );

      final observable = client.watchQuery(
        WatchQueryOptions<String?>(
          document: parseString("""{ fetchPerson { name } }"""),
          parserFn: (data) => data['fetchPerson']?['name'] as String?,
        ),
      );
      client.queryManager.refetchQuery<dynamic>(observable.queryId);
    });

    // Regression test for https://github.com/zino-hofmann/graphql-flutter/issues/1525
    //
    // When a request times out and the underlying link later delivers a
    // successful response, the late event must be ignored rather than
    // completing the already-settled completer (which used to throw an
    // uncaught "Bad state: Future already completed").
    test(
      "late response after queryRequestTimeout does not crash",
      () async {
        final controller = StreamController<Response>();
        when(
          link.request(any),
        ).thenAnswer((_) => controller.stream);

        final timeoutClient = GraphQLClient(
          cache: getTestCache(),
          link: link,
          queryRequestTimeout: const Duration(milliseconds: 50),
        );

        // The request never emits before the timeout fires.
        final result = await timeoutClient.query(
          QueryOptions<dynamic>(
            document: parseString("{ fetchPerson { name } }"),
          ),
        );

        expect(result.hasException, isTrue);
        expect(result.exception!.linkException, isA<UnknownException>());
        expect(
          (result.exception!.linkException as UnknownException)
              .originalException,
          isA<TimeoutException>(),
        );

        // The real response arrives after the timeout already settled the
        // request. This must not throw an uncaught error.
        controller.add(
          Response(
            data: <String, dynamic>{
              'fetchPerson': <String, dynamic>{'name': 'late'},
            },
            response: <String, dynamic>{},
          ),
        );
        await controller.close();

        // Pump the event loop so any late delivery would surface here.
        await Future<void>.delayed(const Duration(milliseconds: 20));
      },
    );

    group('rebroadcast to watchers of one request', () {
      final document = parseString('{ fetchPerson { id name } }');

      Map<String, dynamic> person(String name) => <String, dynamic>{
            '__typename': 'Query',
            'fetchPerson': <String, dynamic>{
              '__typename': 'Person',
              'id': '1',
              'name': name,
            },
          };

      String parseName(Map<String, dynamic> data) =>
          data['fetchPerson']['name'] as String;

      int parseLength(Map<String, dynamic> data) =>
          (data['fetchPerson']['name'] as String).length;

      // Both watchers read the same request but parse it differently, so the
      // result of one cannot be handed to the other.
      for (final firstWatcherIsTyped in [true, false]) {
        test(
          'every watcher gets a result of its own type and parser '
          '(typed first watcher: $firstWatcherIsTyped)',
          () async {
            when(link.request(any)).thenAnswer(
              (_) => Stream.value(
                Response(data: person('ada'), response: <String, dynamic>{}),
              ),
            );

            final ObservableQuery<Object?> first = firstWatcherIsTyped
                ? client.watchQuery(WatchQueryOptions<String>(
                    document: document,
                    fetchPolicy: FetchPolicy.networkOnly,
                    parserFn: parseName,
                  ))
                : client.watchQuery(WatchQueryOptions<Object?>(
                    document: document,
                    fetchPolicy: FetchPolicy.networkOnly,
                  ));
            final second = client.watchQuery(WatchQueryOptions<int>(
              document: document,
              fetchPolicy: FetchPolicy.cacheFirst,
              parserFn: parseLength,
            ));
            final firstConcrete = first.stream.firstWhere((r) => r.isConcrete);
            final secondConcrete =
                second.stream.firstWhere((r) => r.isConcrete);
            first.fetchResults();
            second.fetchResults();
            await Future.wait([firstConcrete, secondConcrete]);

            client.cache.writeQuery(
              Request(operation: Operation(document: document)),
              data: person('robert'),
            );
            await client.queryManager.maybeRebroadcastQueriesAsync(force: true);

            expect(first.latestResult!.data!['fetchPerson']['name'], 'robert');
            expect(second.latestResult!.data!['fetchPerson']['name'], 'robert');
            expect(second.latestResult!.parsedData, 6);
            if (firstWatcherIsTyped) {
              expect(first.latestResult!.parsedData, 'robert');
            }
          },
        );
      }
    });
  });
}
