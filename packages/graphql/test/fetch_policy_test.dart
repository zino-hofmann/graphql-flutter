import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

import 'package:graphql/client.dart';
import 'package:gql/language.dart';

import './helpers.dart';

void main() {
  const String readRepositories = r'''
    query ReadRepositories($nRepositories: Int!) {
      viewer {
        repositories(last: $nRepositories) {
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
  readRepositoryData({bool withTypenames = true, bool withIds = true}) {
    return {
      'viewer': {
        'repositories': {
          'nodes': [
            {
              if (withIds) 'id': 'MDEwOlJlcG9zaXRvcnkyNDgzOTQ3NA==',
              'name': 'pq',
              'viewerHasStarred': false
            },
            {
              if (withIds) 'id': 'MDEwOlJlcG9zaXRvcnkzMjkyNDQ0Mw==',
              'name': 'go-evercookie',
              'viewerHasStarred': false
            },
            {
              if (withIds) 'id': 'MDEwOlJlcG9zaXRvcnkzNTA0NjgyNA==',
              'name': 'watchbot',
              'viewerHasStarred': false
            },
          ]
              .map((map) =>
                  withTypenames ? {'__typename': 'Repository', ...map} : map)
              .toList(),
        },
      },
    };
  }

  late MockLink link;
  late GraphQLClient client;

  group('FetchPolicy', () {
    setUp(() {
      link = MockLink();

      client = GraphQLClient(
        cache: getTestCache(),
        link: link,
      );
    });

    group('query', () {
      // TODO cacheFirst code path: Return result from cache. Only fetch from network if cached result is not available.
      // TODO cacheOnly code path: Return result from cache if available, fail otherwise.
      // TODO noCache code path: Return result from network, fail if network call doesn't succeed, don't save to cache.
      // TODO networkOnly code path: Return result from network, fail if network call doesn't succeed, save to cache.

      test('switch to cacheOnly returns cached data', () async {
        final _options = QueryOptions(
          fetchPolicy: FetchPolicy.cacheAndNetwork,
          document: parseString(readRepositories),
          variables: <String, dynamic>{
            'nRepositories': 42,
          },
        );
        final repoData = readRepositoryData(withTypenames: true);

        when(
          link.request(any),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            Response(data: repoData, response: {}),
          ]),
        );

        final QueryResult r = await client.query(_options);

        verify(
          link.request(
            Request(
              operation: Operation(
                document: parseString(readRepositories),
                //operationName: 'ReadRepositories',
              ),
              variables: <String, dynamic>{
                'nRepositories': 42,
              },
              context: Context(),
            ),
          ),
        );

        expect(r.exception, isNull);
        expect(r.data, equals(repoData));

        final QueryResult cacheResult = await client.query(QueryOptions(
          fetchPolicy: FetchPolicy.cacheOnly,
          document: parseString(readRepositories),
          variables: <String, dynamic>{
            'nRepositories': 42,
          },
        ));
        expect(cacheResult.exception, isNull);
        expect(cacheResult.data, equals(repoData));
      });
      test('cacheAndNetwork returns from cache (if exists)', () async {
        final _options = QueryOptions(
          fetchPolicy: FetchPolicy.cacheAndNetwork,
          document: parseString(readRepositories),
          variables: <String, dynamic>{
            'nRepositories': 42,
          },
        );
        final repoData = readRepositoryData(withTypenames: true);

        when(
          link.request(any),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            Response(data: repoData, response: {}),
          ]),
        );

        final QueryResult r = await client.query(_options);

        verify(
          link.request(
            Request(
              operation: Operation(
                document: parseString(readRepositories),
                //operationName: 'ReadRepositories',
              ),
              variables: <String, dynamic>{
                'nRepositories': 42,
              },
              context: Context(),
            ),
          ),
        );

        expect(r.exception, isNull);
        expect(r.data, equals(repoData));
        expect(r.source, QueryResultSource.network);

        final QueryResult cacheResult = await client.query(_options);
        expect(cacheResult.exception, isNull);
        expect(cacheResult.data, equals(repoData));
        expect(cacheResult.source, equals(QueryResultSource.cache));
      });
    });
  });
}
