import 'package:gql/language.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

import 'package:graphql/client.dart';

import './helpers.dart';

class MockHttpClient extends Mock implements http.Client {}

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

  HttpLink httpLink;
  AuthLink authLink;
  Link link;
  GraphQLClient graphQLClientClient;
  MockHttpClient mockHttpClient;
  group('simple json', () {
    setUp(() {
      mockHttpClient = MockHttpClient();

      httpLink = HttpLink(
          uri: 'https://api.github.com/graphql', httpClient: mockHttpClient);

      authLink = AuthLink(
        getToken: () async => 'Bearer my-special-bearer-token',
      );

      link = authLink.concat(httpLink);

      graphQLClientClient = GraphQLClient(
        cache: getTestCache(),
        link: link,
      );
    });
    group('query', () {
      test('successful query', () async {
        final WatchQueryOptions _options = WatchQueryOptions(
          documentNode: parseString(readRepositories),
          variables: <String, dynamic>{},
        );
        when(
          mockHttpClient.send(any),
        ).thenAnswer((Invocation a) async {
          return simpleResponse(body: r'''
{
  "data": {
    "viewer": {
      "repositories": {
        "nodes": [
          {
            "__typename": "Repository",
            "id": "MDEwOlJlcG9zaXRvcnkyNDgzOTQ3NA==",
            "name": "pq",
            "viewerHasStarred": false
          },
          {
            "__typename": "Repository",
            "id": "MDEwOlJlcG9zaXRvcnkzMjkyNDQ0Mw==",
            "name": "go-evercookie",
            "viewerHasStarred": false
          },
          {
            "__typename": "Repository",
            "id": "MDEwOlJlcG9zaXRvcnkzNTA0NjgyNA==",
            "name": "watchbot",
            "viewerHasStarred": false
          }
        ]
      }
    }
  }
}
        ''');
        });
        final QueryResult r = await graphQLClientClient.query(_options);

        final http.Request capt = verify(mockHttpClient.send(captureAny))
            .captured
            .first as http.Request;
        expect(capt.method, 'post');
        expect(capt.url.toString(), 'https://api.github.com/graphql');
        expect(
          capt.headers,
          <String, String>{
            'accept': '*/*',
            'content-type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer my-special-bearer-token',
          },
        );
        expect(await capt.finalize().bytesToString(),
            r'{"operationName":null,"variables":{},"query":"query {\n  viewer {\n    repositories(last: 42) {\n      nodes {\n        __typename\n        id\n        name\n        viewerHasStarred\n      }\n    }\n  }\n}"}');

        expect(r.exception, isNull);
        expect(r.data, isNotNull);
        final List<Map<String, dynamic>> nodes =
            (r.data['viewer']['repositories']['nodes'] as List<dynamic>)
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
        final MutationOptions _options =
            MutationOptions(documentNode: parseString(addStar));
        when(mockHttpClient.send(any)).thenAnswer((Invocation a) async =>
            simpleResponse(
                body:
                    '{"data":{"action":{"starrable":{"viewerHasStarred":true}}}}'));

        final QueryResult response = await graphQLClientClient.mutate(_options);

        final http.Request request = verify(mockHttpClient.send(captureAny))
            .captured
            .first as http.Request;
        expect(request.method, 'post');
        expect(request.url.toString(), 'https://api.github.com/graphql');
        expect(
          request.headers,
          <String, String>{
            'accept': '*/*',
            'content-type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer my-special-bearer-token',
          },
        );
        expect(await request.finalize().bytesToString(),
            r'{"operationName":null,"variables":{},"query":"mutation {\n  action: addStar(input: {starrableId: \"some_repo\"}) {\n    starrable {\n      viewerHasStarred\n    }\n  }\n}"}');

        expect(response.exception, isNull);
        expect(response.data, isNotNull);
        final bool viewerHasStarred =
            response.data['action']['starrable']['viewerHasStarred'] as bool;
        expect(viewerHasStarred, true);
      });
    });
  });
}
