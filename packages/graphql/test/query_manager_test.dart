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
  });
}
