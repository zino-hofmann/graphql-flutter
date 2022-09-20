import 'package:gql/language.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

import 'package:graphql/client.dart';

import './helpers.dart';

void main() {
  const String readRepositories = r'''{
    viewer {
      repositories(last: 42) {
        nodes {
          __typename
          id
          name
          viewerHasStarred
        }
      }
    }
  }
''';

  const String addStar = r'''mutation {
    action: addStar(input: {starrableId: "some_repo"}) {
      starrable {
        viewerHasStarred
      }
    }
  }
''';

  late MockLink link;
  late GraphQLClient graphQLClientClient;

  group('simple json', () {
    setUp(() {
      link = MockLink();

      graphQLClientClient = GraphQLClient(
        cache: getTestCache(),
        link: link,
      );
    });

    group('query', () {
      test('successful query', () async {
        final WatchQueryOptions _options = WatchQueryOptions(
          document: parseString(readRepositories),
          variables: <String, dynamic>{},
        );

        when(
          link.request(any),
        ).thenAnswer(
          (_) => Stream.fromIterable(
            [
              Response(
                data: <String, dynamic>{
                  'viewer': {
                    'repositories': {
                      'nodes': [
                        {
                          '__typename': 'Repository',
                          'id': 'MDEwOlJlcG9zaXRvcnkyNDgzOTQ3NA==',
                          'name': 'pq',
                          'viewerHasStarred': false,
                        },
                        {
                          '__typename': 'Repository',
                          'id': 'MDEwOlJlcG9zaXRvcnkzMjkyNDQ0Mw==',
                          'name': 'go-evercookie',
                          'viewerHasStarred': false,
                        },
                        {
                          '__typename': 'Repository',
                          'id': 'MDEwOlJlcG9zaXRvcnkzNTA0NjgyNA==',
                          'name': 'watchbot',
                          'viewerHasStarred': false,
                        },
                      ],
                    },
                  },
                },
                response: {},
              ),
            ],
          ),
        );

        final QueryResult r = await graphQLClientClient.query(_options);

        verify(
          link.request(
            Request(
              operation: Operation(
                document: parseString(readRepositories),
                operationName: null,
              ),
              variables: <String, dynamic>{},
              context: Context(),
            ),
          ),
        );

        expect(r.exception, isNull);
        expect(r.data, isNotNull);
        final List<Map<String, dynamic>> nodes =
            (r.data!['viewer']['repositories']['nodes'] as List<dynamic>)
                .cast<Map<String, dynamic>>();
        expect(nodes, hasLength(3));
        expect(nodes[0]['id'], 'MDEwOlJlcG9zaXRvcnkyNDgzOTQ3NA==');
        expect(nodes[1]['name'], 'go-evercookie');
        expect(nodes[2]['viewerHasStarred'], false);
        return;
      });
//    test('failed query because of network', {});
//    test('failed query because of because of error response', {});
//    test('failed query because of because of invalid response', () {
//      String responseBody =
//          '{\"message\":\"Bad credentials\",\"documentation_url\":\"https://developer.github.com/v4\"}';
//      int responseCode = 401;
//    });
//    test('partially success query with some errors', {});
    });
    group('mutation', () {
      test('successful mutation', () async {
        final MutationOptions _options = MutationOptions(
          document: parseString(addStar),
        );

        when(
          link.request(any),
        ).thenAnswer(
          (_) => Stream.fromIterable(
            [
              Response(
                data: <String, dynamic>{
                  'action': {
                    'starrable': {
                      'viewerHasStarred': true,
                    },
                  },
                },
                response: {},
              ),
            ],
          ),
        );

        final QueryResult response = await graphQLClientClient.mutate(_options);

        verify(
          link.request(
            Request(
              operation: Operation(
                document: parseString(addStar),
              ),
              variables: {},
              context: Context(),
            ),
          ),
        );

        expect(response.exception, isNull);
        expect(response.data, isNotNull);
        final bool? viewerHasStarred =
            response.data!['action']['starrable']['viewerHasStarred'] as bool?;
        expect(viewerHasStarred, true);
      });
    });
  });
}
