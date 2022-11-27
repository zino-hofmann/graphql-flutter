import 'package:graphql/src/core/result_parser.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

import 'package:graphql/client.dart';
import 'package:gql/language.dart';

import './helpers.dart';

void main() {
  const String readSingle = r'''
    query ReadSingle($id: ID!) {
      single(id: $id) {
        id,
        __typename,
        name
      }
    }
  ''';

  const String writeSingle = r'''
    mutation WriteSingle($id: ID!, $name: String!) {
      updateSingle(id: $id, name: $name) {
        id,
        __typename,
        name
      }
    }
  ''';

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
  Map<String, dynamic> readRepositoryData({
    bool withTypenames = true,
    bool withIds = true,
    bool viewerHasStarred = false,
  }) {
    return {
      'viewer': {
        'repositories': {
          'nodes': [
            {
              if (withIds) 'id': 'MDEwOlJlcG9zaXRvcnkyNDgzOTQ3NA==',
              'name': 'pq',
              'viewerHasStarred': viewerHasStarred
            },
            {
              if (withIds) 'id': 'MDEwOlJlcG9zaXRvcnkzMjkyNDQ0Mw==',
              'name': 'go-evercookie',
              'viewerHasStarred': viewerHasStarred
            },
            {
              if (withIds) 'id': 'MDEwOlJlcG9zaXRvcnkzNTA0NjgyNA==',
              'name': 'watchbot',
              'viewerHasStarred': viewerHasStarred
            },
          ]
              .map((map) =>
                  withTypenames ? {'__typename': 'Repository', ...map} : map)
              .toList(),
        },
      },
    };
  }

  const String addStar = r'''
    mutation AddStar($starrableId: ID!) {
      action: addStar(input: {starrableId: $starrableId}) {
        starrable {
          viewerHasStarred
        }
      }
    }
  ''';

  late MockLink link;
  late GraphQLClient client;

  group('simple json', () {
    setUp(() {
      link = MockLink();

      client = GraphQLClient(
        cache: getTestCache(),
        link: link,
      );
    });

    group('query', () {
      test('successful response', () async {
        final _options = QueryOptions(
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
            Response(
              data: repoData,
              context: Context().withEntry(
                HttpLinkResponseContext(
                  statusCode: 200,
                  headers: {'foo': 'bar'},
                ),
              ),
              response: {},
            ),
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

        expect(
          r.context.entry<HttpLinkResponseContext>()!.statusCode,
          equals(200),
        );
        expect(
          r.context.entry<HttpLinkResponseContext>()!.headers!['foo'],
          equals('bar'),
        );
      });
      test('issue 1208', () async {
        final client = GraphQLClient(
          cache: GraphQLCache(
            possibleTypes: {
              'WalletContentBlock': {'WalletContentBlockList'},
              'WalletContentItem': {'WalletContentItemContentPreview'}
            },
          ),
          link: link,
        );
        const data = {
          "__typename": "Query",
          "walletGetContent": {
            "__typename": "WalletGetContentPayload",
            "blocks": [
              {
                "__typename": "WalletContentBlockList",
                "id": "1",
                "blockType": {
                  "__typename": "WalletContentBlockType",
                  "id": "horizontal-scrolling-list",
                },
                "caption": "Featured",
                "items": [
                  {
                    "__typename": "WalletContentItemContentPreview",
                    "id": "1",
                    "caption": "Remarkable Women #4740",
                    "imageURL":
                        "https://lh3.googleusercontent.com/1kXncBpOzPjZAC46GDNXvW4NL0zDv1e_E6vzsTtKEAOAvb0SwbWzwljDY5hulMqRA4zQytjYjV7B-a_jYtNG6zy9dKssov9RRRLu5ss=w600",
                    "link":
                        "https://opensea.io/assets/ethereum/0x3e69baab7a742c83499661c5db92386b2424df11/4740"
                  },
                  {
                    "__typename": "WalletContentItemContentPreview",
                    "id": "2",
                    "caption": "Inftspaces",
                    "imageURL":
                        "https://lh3.googleusercontent.com/8h6WQ4_Kxn0c6rBujSe0flZMTSKiWGWiMOSNaSTPUchakVq4TmyBOWJi4E0GU3_5b7v4jF-vIPR24uziltXMfQHgzEj3zBCkW_Tbsw=s0",
                    "link":
                        "https://opensea.io/assets/ethereum/0xb11288c7237765db4782dfddcc49e31bb80132b8/90"
                  },
                  {
                    "__typename": "WalletContentItemContentPreview",
                    "id": "3",
                    "caption": "Love on Mars",
                    "imageURL":
                        "https://lh3.googleusercontent.com/XoOJwf3DQ6ZWMpmmLkVqfZD3AqEM3G0xQCXNur0-u5-HAHpoMHyPJQL__5H0wpJsy2cafaaCSSxI5YPjnzCZ-4ME7hnJXrgd5292nA=s0",
                    "link":
                        "https://opensea.io/collection/love-on-mars-by-ruben-rojas-x-omgdrops"
                  }
                ]
              },
              {
                "__typename": "WalletContentBlockList",
                "id": "2",
                "blockType": {
                  "__typename": "WalletContentBlockType",
                  "id": "vertical-short-list"
                },
                "caption": "New",
                "items": [
                  {
                    "__typename": "WalletContentItemContentPreview",
                    "id": "4",
                    "caption": "MSO LAB Genesis #844",
                    "imageURL":
                        "https://lh3.googleusercontent.com/FCcSKSsYaNk9-bzks7ZWIEjFPiL8xrtb8aYnO2DG0piF9Eja1AkY55Yan-KQqtpcwISdpTWNz_W0yrmmmQM2hAHNG_AIXl7E4ATG2Q=w600",
                    "link":
                        "https://opensea.io/assets/ethereum/0xc2ac394984f3850027dac95fe8a62e446c5fb786/844"
                  },
                  {
                    "__typename": "WalletContentItemContentPreview",
                    "id": "5",
                    "caption": "The Outsiders Genesis",
                    "imageURL":
                        "https://lh3.googleusercontent.com/AM8EkaQl32uR8N1RIiJa5ogVG1gh2faX6u4a1TAa_NhsGkA2CRG0pFfMOOxcc09q2KFq5cQNljTFkDbbScWpUT70es83Di0RRWD7fjM=s0",
                    "link":
                        "https://opensea.io/collection/the-outsiders-genesis"
                  },
                  {
                    "__typename": "WalletContentItemContentPreview",
                    "id": "6",
                    "caption": "Bored Ape Yacht Club #6386",
                    "imageURL":
                        "https://img.seadn.io/files/968a4be8ada4a55b59de561d15522b4e.png?fit=max&w=600",
                    "link":
                        "https://opensea.io/assets/ethereum/0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d/6386"
                  }
                ]
              }
            ]
          }
        };
        final _options = QueryOptions(
          document: parseString(r'''
query WalletGetContent($input: WalletGetContentInput!) {
  __typename
  walletGetContent(input: $input) {
    __typename
    blocks {
    __typename
    ... on WalletContentBlockList {
  __typename
        id
        blockType {
  __typename
          id
        }
        caption
        items {
  __typename
          ... on WalletContentItemContentPreview {
  __typename
            id
            caption
            imageURL
            link
          }
        }
      }
    }
  }
}
'''),
          variables: <String, dynamic>{
            'input': {'id': 'foo'},
          },
        );

        when(
          link.request(any),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            Response(
              data: data,
              context: Context().withEntry(
                HttpLinkResponseContext(
                  statusCode: 200,
                  headers: {'foo': 'bar'},
                ),
              ),
              response: {},
            ),
          ]),
        );

        final QueryResult r = await client.query(_options);
        expect(r.exception, isNull);
        expect(r.data, equals(data));
      });
      test('issue 1208, duplicate IDs', () async {
        final client = GraphQLClient(
          cache: GraphQLCache(
            possibleTypes: {
              'WalletContentBlock': {'WalletContentBlockList'},
              'WalletContentItem': {'WalletContentItemContentPreview'}
            },
          ),
          link: link,
        );
        const data = {
          "__typename": "Query",
          "walletGetContent": {
            "__typename": "WalletGetContentPayload",
            "blocks": [
              {
                "__typename": "WalletContentBlockList",
                "id": "1",
                "blockType": {
                  "__typename": "WalletContentBlockType",
                  "id": "horizontal-scrolling-list",
                },
                "caption": "Featured",
                "items": [
                  {
                    "__typename": "WalletContentItemContentPreview",
                    "id": "1",
                    "caption": "Remarkable Women #4740",
                    "imageURL":
                        "https://lh3.googleusercontent.com/1kXncBpOzPjZAC46GDNXvW4NL0zDv1e_E6vzsTtKEAOAvb0SwbWzwljDY5hulMqRA4zQytjYjV7B-a_jYtNG6zy9dKssov9RRRLu5ss=w600",
                    "link":
                        "https://opensea.io/assets/ethereum/0x3e69baab7a742c83499661c5db92386b2424df11/4740"
                  },
                  {
                    "__typename": "WalletContentItemContentPreview",
                    "id": "2",
                    "caption": "Inftspaces",
                    "imageURL":
                        "https://lh3.googleusercontent.com/8h6WQ4_Kxn0c6rBujSe0flZMTSKiWGWiMOSNaSTPUchakVq4TmyBOWJi4E0GU3_5b7v4jF-vIPR24uziltXMfQHgzEj3zBCkW_Tbsw=s0",
                    "link":
                        "https://opensea.io/assets/ethereum/0xb11288c7237765db4782dfddcc49e31bb80132b8/90"
                  },
                  {
                    "__typename": "WalletContentItemContentPreview",
                    "id": "3",
                    "caption": "Love on Mars",
                    "imageURL":
                        "https://lh3.googleusercontent.com/XoOJwf3DQ6ZWMpmmLkVqfZD3AqEM3G0xQCXNur0-u5-HAHpoMHyPJQL__5H0wpJsy2cafaaCSSxI5YPjnzCZ-4ME7hnJXrgd5292nA=s0",
                    "link":
                        "https://opensea.io/collection/love-on-mars-by-ruben-rojas-x-omgdrops"
                  }
                ]
              },
              {
                "__typename": "WalletContentBlockList",
                "id": "2",
                "blockType": {
                  "__typename": "WalletContentBlockType",
                  "id": "vertical-short-list"
                },
                "caption": "New",
                "items": [
                  {
                    "__typename": "WalletContentItemContentPreview",
                    "id": "1",
                    "caption": "MSO LAB Genesis #844",
                    "imageURL":
                        "https://lh3.googleusercontent.com/FCcSKSsYaNk9-bzks7ZWIEjFPiL8xrtb8aYnO2DG0piF9Eja1AkY55Yan-KQqtpcwISdpTWNz_W0yrmmmQM2hAHNG_AIXl7E4ATG2Q=w600",
                    "link":
                        "https://opensea.io/assets/ethereum/0xc2ac394984f3850027dac95fe8a62e446c5fb786/844"
                  },
                  {
                    "__typename": "WalletContentItemContentPreview",
                    "id": "2",
                    "caption": "The Outsiders Genesis",
                    "imageURL":
                        "https://lh3.googleusercontent.com/AM8EkaQl32uR8N1RIiJa5ogVG1gh2faX6u4a1TAa_NhsGkA2CRG0pFfMOOxcc09q2KFq5cQNljTFkDbbScWpUT70es83Di0RRWD7fjM=s0",
                    "link":
                        "https://opensea.io/collection/the-outsiders-genesis"
                  },
                  {
                    "__typename": "WalletContentItemContentPreview",
                    "id": "3",
                    "caption": "Bored Ape Yacht Club #6386",
                    "imageURL":
                        "https://img.seadn.io/files/968a4be8ada4a55b59de561d15522b4e.png?fit=max&w=600",
                    "link":
                        "https://opensea.io/assets/ethereum/0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d/6386"
                  }
                ]
              }
            ]
          }
        };
        final _options = QueryOptions(
          document: parseString(r'''
query WalletGetContent($input: WalletGetContentInput!) {
  __typename
  walletGetContent(input: $input) {
    __typename
    blocks {
    __typename
    ... on WalletContentBlockList {
  __typename
        id
        blockType {
  __typename
          id
        }
        caption
        items {
  __typename
          ... on WalletContentItemContentPreview {
  __typename
            id
            caption
            imageURL
            link
          }
        }
      }
    }
  }
}
'''),
          variables: <String, dynamic>{
            'input': {'id': 'foo'},
          },
        );

        when(
          link.request(any),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            Response(
              data: data,
              context: Context().withEntry(
                HttpLinkResponseContext(
                  statusCode: 200,
                  headers: {'foo': 'bar'},
                ),
              ),
              response: {},
            ),
          ]),
        );

        final QueryResult r = await client.query(_options);
        expect(r.exception, isNull);
        expect(
            r.data,
            equals({
              ...data,
              "walletGetContent": {
                ...data["walletGetContent"] as Map<String, dynamic>,
                "blocks": [
                  {
                    ...(data["walletGetContent"]
                            as Map<String, dynamic>)["blocks"][0]
                        as Map<String, dynamic>,
                    "items": ((data["walletGetContent"]
                            as Map<String, dynamic>)["blocks"][1]
                        as Map<String, dynamic>)["items"],
                  },
                  {
                    ...(data["walletGetContent"]
                            as Map<String, dynamic>)["blocks"][1]
                        as Map<String, dynamic>,
                    "items": ((data["walletGetContent"]
                            as Map<String, dynamic>)["blocks"][1]
                        as Map<String, dynamic>)["items"],
                  }
                ]
              }
            }));
      });

      test('successful response with parser', () async {
        final ResultParserFn<List<String>> parserFn = (data) {
          return (data['viewer']['repositories']['nodes'] as List)
              .map<String>((node) => node['name'] as String)
              .toList();
        };
        final _options = QueryOptions(
          document: parseString(readRepositories),
          variables: <String, dynamic>{
            'nRepositories': 42,
          },
          parserFn: parserFn,
        );
        final repoData = readRepositoryData(withTypenames: true);

        when(
          link.request(any),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            Response(
              data: repoData,
              context: Context().withEntry(
                HttpLinkResponseContext(
                  statusCode: 200,
                  headers: {'foo': 'bar'},
                ),
              ),
              response: {},
            ),
          ]),
        );

        final QueryResult<List<String>> r = await client.query(_options);

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

        List<String>? parsedData = r.parsedData;
        expect(
            parsedData,
            equals([
              'pq',
              'go-evercookie',
              'watchbot',
            ]));

        expect(
          r.context.entry<HttpLinkResponseContext>()!.statusCode,
          equals(200),
        );
        expect(
          r.context.entry<HttpLinkResponseContext>()!.headers!['foo'],
          equals('bar'),
        );
      });
      test('successful fetch-more with parser', () async {
        final ResultParserFn<List<String>> parserFn = (data) {
          return (data['viewer']['repositories']['nodes'] as List)
              .map<String>((node) => node['name'] as String)
              .toList();
        };
        final _options = QueryOptions(
          document: parseString(readRepositories),
          variables: <String, dynamic>{
            'nRepositories': 42,
          },
          parserFn: parserFn,
        );
        final repoData = readRepositoryData(withTypenames: true);

        when(
          link.request(any),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            Response(
              data: repoData,
              context: Context().withEntry(
                HttpLinkResponseContext(
                  statusCode: 200,
                  headers: {'foo': 'bar'},
                ),
              ),
              response: {},
            ),
          ]),
        );

        final QueryResult<List<String>> r1 = await client.query(_options);
        expect(r1.exception, isNull);
        expect(r1.data, equals(repoData));
        expect(
            r1.parsedData,
            equals([
              'pq',
              'go-evercookie',
              'watchbot',
            ]));
        final QueryResult<List<String>> r2 = await client.fetchMore(
          FetchMoreOptions(
            updateQuery: (d1, d2) => ({
              'viewer': {
                'repositories': {
                  'nodes': [
                    ...(d1!['viewer']['repositories']['nodes'] as List),
                    ...(d2!['viewer']['repositories']['nodes'] as List),
                  ]
                }
              }
            }),
          ),
          previousResult: r1,
          originalOptions: _options,
        );

        expect(r2.exception, isNull);
        expect(
            r2.parsedData,
            equals([
              'pq',
              'go-evercookie',
              'watchbot',
              'pq',
              'go-evercookie',
              'watchbot',
            ]));
      });

      test('successful response without normalization', () async {
        final readUnidentifiedRepositories = parseString(r'''
            query ReadRepositories($nRepositories: Int!) {
              viewer {
                repositories(last: $nRepositories) {
                  nodes {
                    name
                    viewerHasStarred
                  }
                }
              }
            }
          ''');
        final repoData = readRepositoryData(
          withTypenames: false,
          withIds: false,
        );

        final _options = QueryOptions(
          document: readUnidentifiedRepositories,
          variables: {'nRepositories': 42},
        );

        when(
          link.request(any),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            Response(data: repoData, response: {}),
          ]),
        );

        final QueryResult r = await client.query(_options);

        verify(link.request(_options.asRequest));
        expect(r.data, equals(repoData));
      });
      test('correct consecutive responses', () async {
        final _options = QueryOptions(
          fetchPolicy: FetchPolicy.networkOnly,
          document: parseString(readRepositories),
          variables: <String, dynamic>{
            'nRepositories': 42,
          },
        );
        final firstData =
            readRepositoryData(withTypenames: true, viewerHasStarred: false);
        final secondData =
            readRepositoryData(withTypenames: true, viewerHasStarred: true);

        final resp = (Map<String, dynamic> d) => Stream.fromIterable([
              Response(
                data: d,
                context: Context().withEntry(
                  HttpLinkResponseContext(
                    statusCode: 200,
                    headers: {'foo': 'bar'},
                  ),
                ),
                response: {},
              )
            ]);

        when(link.request(any)).thenAnswer((_) => resp(firstData));
        QueryResult r = await client.query(_options);
        expect(r.exception, isNull);
        expect(r.data, equals(firstData));

        when(link.request(any)).thenAnswer((_) => resp(secondData));
        r = await client.query(_options);
        expect(r.exception, isNull);
        expect(r.data, equals(secondData));
      });

      test('malformed server response', () async {
        final _options = QueryOptions(
          document: parseString(readRepositories),
          variables: {'nRepositories': 42},
        );
        final malformedRepoData = {
          'viewer': {
            // maybe the server doesn't validate response structures properly,
            // or a user generates a response on the client, etc
            'repos': readRepositoryData()['viewer']!['repositories']
          },
        };

        when(
          link.request(any),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            Response(data: malformedRepoData, response: {}),
          ]),
        );

        final QueryResult r = await client.query(_options);

        expect(r.data, equals(malformedRepoData),
            reason: 'Malformed data should be passed along with errors');

        throwsA(isA<PartialDataException>().having(
          (e) => e.path,
          'An accurate path to the first missing subfield',
          ['a', 'b', '__typename'],
        ));
      });

      test('failed query because of an exception with null string', () async {
        final e = Exception();

        when(
          link.request(any),
        ).thenAnswer(
          (_) => Stream.fromFuture(Future.error(e)),
        );

        final QueryResult r = await client.query(
          WatchQueryOptions(
            document: parseString(readRepositories),
          ),
        );

        expect(
          r.exception!.linkException!.originalException,
          e,
        );
      });

      test('failed query because of an exception with empty string', () async {
        final e = Exception('');

        when(
          link.request(any),
        ).thenAnswer(
          (_) => Stream.fromFuture(Future.error(e)),
        );

        final QueryResult r = await client.query(
          WatchQueryOptions(
            document: parseString(readRepositories),
          ),
        );

        expect(
          r.exception!.linkException!.originalException,
          e,
        );
      });
//    test('failed query because of because of error response', {});
//    test('failed query because of because of invalid response', () {
//      String responseBody =
//          '{\"message\":\"Bad credentials\",\"documentation_url\":\"https://developer.github.com/v4\"}';
//      int responseCode = 401;
//    });
//    test('partially success query with some errors', {});
    });
    group('mutation', () {
      test('query stream notified', () async {
        final initialQueryResponse = Response(
          data: <String, dynamic>{
            'single': {
              'id': '1',
              '__typename': 'Single',
              'name': 'initialQueryName',
            },
          },
          response: {},
        );
        when(
          link.request(any),
        ).thenAnswer(
          (_) => Stream.fromIterable(
            [initialQueryResponse],
          ),
        );

        final observable = client.watchQuery(
          WatchQueryOptions(
            document: parseString(readSingle),
            eagerlyFetchResults: true,
            variables: {'id': '1'},
          ),
        );

        expect(
          observable.stream,
          emitsInOrder(
            [
              // we have no optimistic result
              isA<QueryResult>().having(
                (result) => result.isLoading,
                'loading result',
                true,
              ),
              isA<QueryResult>().having(
                (result) => result.data!['single']['name'],
                'initial query result',
                'initialQueryName',
              ),
              isA<QueryResult>().having(
                (result) => result.data!['single']['name'],
                'result caused by mutation',
                'newNameFromMutation',
              )
            ],
          ),
        );

        final mutationResponseWithNewName = Response(
          data: <String, dynamic>{
            'updateSingle': {
              'id': '1',
              '__typename': 'Single',
              'name': 'newNameFromMutation',
            },
          },
          response: {},
        );
        when(
          link.request(any),
        ).thenAnswer(
          (_) => Stream.fromIterable(
            [mutationResponseWithNewName],
          ),
        );

        final variables = {'id': '1', 'name': 'newNameFromMutation'};

        final QueryResult response = await client.mutate(MutationOptions(
            document: parseString(writeSingle), variables: variables));

        expect(response.data!['updateSingle']['name'], variables['name']);
      });

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

        final QueryResult response = await client.mutate(_options);

        verify(
          link.request(
            Request(
              operation: Operation(
                document: parseString(addStar),
                //operationName: 'AddStar',
              ),
              variables: <String, dynamic>{},
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
      test('successful mutation with parser', () async {
        final ResultParserFn<bool> resultParser =
            (data) => data['action']['starrable']['viewerHasStarred'] as bool;
        final _options = MutationOptions(
          document: parseString(addStar),
          parserFn: resultParser,
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

        final response = await client.mutate(_options);

        verify(
          link.request(
            Request(
              operation: Operation(
                document: parseString(addStar),
                //operationName: 'AddStar',
              ),
              variables: <String, dynamic>{},
              context: Context(),
            ),
          ),
        );
        final bool? parsedResult = response.parsedData;
        expect(parsedResult, isTrue);
        expect(response.exception, isNull);
        expect(response.data, isNotNull);
        final bool? viewerHasStarred =
            response.data!['action']['starrable']['viewerHasStarred'] as bool?;
        expect(viewerHasStarred, true);
      });

      test('successful mutation through watchQuery', () async {
        final _options = MutationOptions(
          document: parseString(addStar),
          variables: {},
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

        final observableQuery = client.watchQuery(WatchQueryOptions(
          document: _options.document,
          variables: _options.variables,
          fetchResults: false,
        ));

        final result = await observableQuery.fetchResults().networkResult!;

        verify(
          link.request(
            Request(
              operation: Operation(
                document: parseString(addStar),
                //operationName: 'AddStar',
              ),
              variables: <String, dynamic>{},
              context: Context(),
            ),
          ),
        );

        expect(result.hasException, isFalse);
        expect(result.data, isNotNull);
        final bool? viewerHasStarred =
            result.data!['action']['starrable']['viewerHasStarred'] as bool?;
        expect(viewerHasStarred, true);
      });
    });

    group('subscription', () {
      test('results', () async {
        final responses = [
          {
            'id': '1',
            'name': 'first',
          },
          {
            'id': '2',
            'name': 'second',
          },
        ].map((item) => Response(
              data: <String, dynamic>{
                'item': {
                  '__typename': 'Item',
                  ...item,
                },
              },
              response: {},
            ));
        when(
          link.request(any),
        ).thenAnswer(
          (_) => Stream.fromIterable(responses),
        );

        final stream = client.subscribe(
          SubscriptionOptions(
            document: parseString(
              r'''
                subscription {
                  item {
                    id
                    name
                  }
                }
              ''',
            ),
          ),
        );

        expect(
          stream,
          emitsInOrder(
            [
              isA<QueryResult>().having(
                (result) => result.data!['item']['name'],
                'first subscription item',
                'first',
              ),
              isA<QueryResult>().having(
                (result) => result.data!['item']['name'],
                'second subscription item',
                'second',
              )
            ],
          ),
        );
      });
      test('broadcasts', () async {
        const initialName = 'initial';
        const firstUpdateName = 'first';
        const secondUpdateName = 'second';
        final initialQueryResponse = Response(
          data: <String, dynamic>{
            'single': {
              'id': '1',
              '__typename': 'Item',
              'name': initialName,
            },
          },
          response: {},
        );
        when(
          link.request(any),
        ).thenAnswer(
          (_) => Stream.fromIterable(
            [initialQueryResponse],
          ),
        );

        final observable = client.watchQuery(
          WatchQueryOptions(
            document: parseString(readSingle),
            eagerlyFetchResults: true,
            variables: {'id': '1'},
          ),
        );
        final responses = [
          {'id': '1', 'name': firstUpdateName, '__typename': 'Item'},
          {'id': '1', 'name': secondUpdateName, '__typename': 'Item'},
        ].map((item) =>
            Response(data: <String, dynamic>{'item': item}, response: {}));
        when(
          link.request(any),
        ).thenAnswer(
          (_) => Stream.fromIterable(responses),
        );
        final stream = client.subscribe(
          SubscriptionOptions(
            document: parseString(
              r'''
                subscription {
                  item {
                    id
                    name
                  }
                }
              ''',
            ),
          ),
        );
        expect(
          stream,
          emitsInOrder(
            [
              isA<QueryResult>().having(
                (result) => result.data!['item']['name'],
                'name',
                firstUpdateName,
              ),
              isA<QueryResult>().having(
                (result) => result.data!['item']['name'],
                'name',
                secondUpdateName,
              )
            ],
          ),
        );
        expect(
          observable.stream,
          emitsInOrder(
            [
              isA<QueryResult>().having(
                (result) => result.data,
                'name',
                null,
              ),
              isA<QueryResult>().having(
                (result) => result.data!['single']['name'],
                'name',
                initialName,
              ),
              isA<QueryResult>().having(
                (result) => result.data!['single']['name'],
                'name',
                firstUpdateName,
              ),
              isA<QueryResult>().having(
                (result) => result.data!['single']['name'],
                'name',
                secondUpdateName,
              )
            ],
          ),
        );
      });
      test('parses results', () async {
        final responses = [
          {'id': '1', 'name': 'first', '__typename': 'Item'},
          {'id': '2', 'name': 'second', '__typename': 'Item'},
        ].map((item) =>
            Response(data: <String, dynamic>{'item': item}, response: {}));
        when(link.request(any))
            .thenAnswer((_) => Stream.fromIterable(responses));

        final ResultParserFn<String> parserFn =
            (data) => data['item']['name'] as String;
        ;

        final stream = client.subscribe(
          SubscriptionOptions(
            parserFn: parserFn,
            document: parseString(
              r'''
                subscription {
                  item {
                    id
                    name
                  }
                }
              ''',
            ),
          ),
        );

        expect(
          stream,
          emitsInOrder(['first', 'second']
              .map((e) => isA<QueryResult<String>>().having((result) {
                    final String? parsed = result.parsedData;
                    return parsed;
                  }, "Parsed item", e))),
        );
      });

      test('wraps stream exceptions', () async {
        final ex = ServerException(
          parsedResponse: null,
          originalException: Error(),
        );

        when(
          link.request(any),
        ).thenAnswer(
          (_) => Stream.error(ex),
        );

        final stream = client.subscribe(
          SubscriptionOptions(
            document: parseString(
              r'''
                subscription {
                  item {
                    id
                    name
                  }
                }
              ''',
            ),
          ),
        );

        expect(
          stream,
          emitsInOrder(
            [
              isA<QueryResult>().having(
                (result) => result.exception!.linkException,
                'wrapped exception',
                ex,
              ),
            ],
          ),
        );
      });
      test('wraps all exceptions from outside of stream', () async {
        final err = Error();

        when(
          link.request(any),
        ).thenThrow(err);

        final stream = client.subscribe(
          SubscriptionOptions(
            document: parseString(
              r'''
                subscription {
                  item {
                    id
                    name
                  }
                }
              ''',
            ),
          ),
        );

        expect(
          stream,
          emitsInOrder(
            [
              isA<QueryResult>().having(
                (result) => result.exception!.linkException!.originalException,
                'wrapped exception',
                err,
              ),
            ],
          ),
        );
      });
    });
  });

  group('direct cache access', () {
    setUp(() {
      link = MockLink();

      client = GraphQLClient(
        cache: getTestCache(),
        link: link,
      );
    });

    test('all methods with exposition', () {
      /// entity identifiers for normalization
      final idFields = {'__typename': 'MyType', 'id': 1};

      /// The direct cache API uses `gql_link` Requests directly
      /// These can also be obtained via `options.asRequest` from any `Options` object,
      /// or via `Operation(document: gql(...)).asRequest()`
      final queryRequest = Request(
        operation: Operation(
          document: gql(
            r'''{
              someField {
                id,
                myField
              }
            }''',
          ),
        ),
      );

      final queryData = {
        '__typename': 'Query',
        'someField': {
          ...idFields,
          'myField': 'originalValue',
        },
      };

      /// `broadcast: true` (the default) would rebroadcast cache updates to all safe instances of `ObservableQuery`
      /// **NOTE**: only `GraphQLClient` can immediately call for a query rebroadcast. if you request a rebroadcast directly
      /// from the cache, it still has to wait for the client to check in on it
      client.writeQuery(queryRequest, data: queryData, broadcast: false);

      /// `optimistic: true` (the default) integrates optimistic data
      /// written to the cache into your read.
      expect(
          client.readQuery(queryRequest, optimistic: false), equals(queryData));

      /// While fragments are never executed themselves, we provide a `gql_link`-like API for consistency.
      /// These can also be obtained via `Fragment(document: gql(...)).asRequest()`.
      final fragmentRequest = FragmentRequest(
        fragment: Fragment(
          document: gql(
            r'''
                fragment mySmallSubset on MyType {
                  myField,
                  someNewField
                }
              ''',
          ),
        ),
        idFields: idFields,
      );

      /// We've specified `idFields` and are only editing a subset of the data
      final fragmentData = {
        'myField': 'updatedValue',
        'someNewField': [
          {'newData': false}
        ],
      };

      /// We didn't disable `broadcast`, so all instances of `ObservableQuery` will be notified of any changes
      client.writeFragment(fragmentRequest, data: fragmentData);

      /// __typename is automatically included in all reads
      expect(
        client.readFragment(fragmentRequest),
        equals({
          '__typename': 'MyType',
          ...fragmentData,
        }),
      );

      final updatedQueryData = {
        '__typename': 'Query',
        'someField': {
          ...idFields,
          'myField': 'updatedValue',
        },
      };

      /// `myField` is updated, but we don't have `someNewField`, as expected.
      expect(client.readQuery(queryRequest), equals(updatedQueryData));
    });
  });

  group("Client management", () {
    setUp(() {
      link = MockLink();

      client = GraphQLClient(
        cache: getTestCache(),
        link: link,
      );
    });

    test('successful response with update link', () async {
      final _options = QueryOptions(
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
          Response(
            data: repoData,
            context: Context().withEntry(
              HttpLinkResponseContext(
                statusCode: 200,
                headers: {'foo': 'bar'},
              ),
            ),
            response: {},
          ),
        ]),
      );
      // FIXME(vincenzopalazzo): adding a new mock link, maybe to print some addition
      // information.
      link = MockLink();
      when(
        link.request(any),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          Response(
            data: repoData,
            context: Context().withEntry(
              HttpLinkResponseContext(
                statusCode: 200,
                headers: {'foo': 'bar'},
              ),
            ),
            response: {},
          ),
        ]),
      );

      client = client.copyWith(link: link);
      final QueryResult r = await client.query(_options);

      expect(r.exception, isNull);
      expect(r.data, equals(repoData));

      expect(
        r.context.entry<HttpLinkResponseContext>()!.statusCode,
        equals(200),
      );
      expect(
        r.context.entry<HttpLinkResponseContext>()!.headers!['foo'],
        equals('bar'),
      );
    });
  });
}
