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
  });
}
