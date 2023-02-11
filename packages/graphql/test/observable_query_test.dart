import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

import 'package:graphql/client.dart';
import 'package:gql/language.dart';

import './helpers.dart';

void main() {
  const String readSingle = r'''
    query ReadSingle() {
      single() {
        id,
        __typename,
        name
      }
    }
  ''';
  const data = {
    'single': {
      'id': '1',
      '__typename': 'Single',
      'name': 'initialQueryName',
    },
  };
  const pollDuration = Duration(milliseconds: 20);

  final queryResponseMatcher = isA<QueryResult>().having(
    (result) => result.data!['single']['name'],
    'name',
    'initialQueryName',
  );

  late MockLink link;
  late GraphQLClient client;

  group('observable query ', () {
    setUp(() {
      link = MockLink();

      client = GraphQLClient(
        cache: getTestCache(),
        link: link,
      );

      final queryResponse = Response(data: data, response: {});
      when(
        link.request(any),
      ).thenAnswer(
        (_) => Stream.fromIterable(
          [queryResponse],
        ),
      );
    });
    test('can start poller', () async {
      final observable = client.watchQuery(
        WatchQueryOptions(
          document: parseString(readSingle),
        ),
      );
      expect(
        observable.stream,
        emitsInOrder(
          [queryResponseMatcher, queryResponseMatcher, emitsDone],
        ),
      );
      observable.startPolling(pollDuration);
      await Future<void>.delayed(pollDuration * 2.1);
      observable.close();
    }, timeout: Timeout(Duration(seconds: 1)));
    test('can stop poller', () async {
      final observable = client.watchQuery(
        WatchQueryOptions(
          document: parseString(readSingle),
        ),
      );
      expect(
        observable.stream,
        neverEmits(
          isA<QueryResult>().having(
            (result) => result.data!['single']['name'],
            'name',
            'initialQueryName',
          ),
        ),
      );
      observable.startPolling(pollDuration);
      observable.stopPolling();
      await Future<void>.delayed(pollDuration * 2.1);
      observable.close();
    }, timeout: Timeout(Duration(seconds: 1)));
    test('can deduplicate startPolling calls with the same duration', () async {
      final observable = client.watchQuery(
        WatchQueryOptions(
          document: parseString(readSingle),
        ),
      );
      expect(
        observable.stream,
        emitsInOrder(
          [queryResponseMatcher, queryResponseMatcher, emitsDone],
        ),
      );
      observable.startPolling(pollDuration);
      observable.startPolling(pollDuration);
      observable.startPolling(pollDuration);
      await Future<void>.delayed(pollDuration * 2.1);
      observable.close();
    }, timeout: Timeout(Duration(seconds: 1)));
    test('can deduplicate startPolling calls with different durations',
        () async {
      final observable = client.watchQuery(
        WatchQueryOptions(
          document: parseString(readSingle),
        ),
      );
      expect(
        observable.stream,
        emitsInOrder(
          [
            queryResponseMatcher,
            queryResponseMatcher,
            queryResponseMatcher,
            emitsDone
          ],
        ),
      );
      observable.startPolling(Duration(milliseconds: 10));
      observable.startPolling(Duration(milliseconds: 20));
      observable.startPolling(Duration(milliseconds: 30));
      observable.startPolling(pollDuration);
      await Future<void>.delayed(pollDuration * 3.1);
      observable.close();
    }, timeout: Timeout(Duration(seconds: 1)));
    test('can stop pollers in quick succession', () async {
      final observable = client.watchQuery(
        WatchQueryOptions(
          document: parseString(readSingle),
        ),
      );
      expect(
        observable.stream,
        emitsInOrder(
          [
            queryResponseMatcher,
            queryResponseMatcher,
            queryResponseMatcher,
            emitsDone
          ],
        ),
      );
      observable.startPolling(pollDuration);
      observable.stopPolling();
      observable.startPolling(pollDuration);
      observable.stopPolling();
      observable.startPolling(pollDuration);
      await Future<void>.delayed(pollDuration * 3.1);
      observable.close();
    }, timeout: Timeout(Duration(seconds: 1)));
  });
}
