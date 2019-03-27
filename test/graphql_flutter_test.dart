import 'dart:convert';
import 'dart:io' show File, Platform;

import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:graphql_flutter/graphql_flutter.dart';

class MockHttpClient extends Mock implements http.Client {}

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

  const String addStar = r'''
  mutation AddStar($starrableId: ID!) {
    action: addStar(input: {starrableId: $starrableId}) {
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

  setUp(() {
    mockHttpClient = MockHttpClient();

    httpLink = HttpLink(
        uri: 'https://api.github.com/graphql', httpClient: mockHttpClient);

    authLink = AuthLink(
      getToken: () async => 'Bearer my-special-bearer-token',
    );

    link = authLink.concat(httpLink);

    graphQLClientClient = GraphQLClient(
      cache: NormalizedInMemoryCache(
        dataIdFromObject: typenameDataIdFromObject,
      ),
      link: link,
    );
  });
  group('query', () {
    test('successful query', () async {
      final WatchQueryOptions _options = WatchQueryOptions(
        document: readRepositories,
        variables: <String, dynamic>{
          'nRepositories': 42,
        },
      );
      when(
        mockHttpClient.send(any),
      ).thenAnswer((Invocation a) async {
        const String body = '''
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
        ''';

        final List<int> bytes = utf8.encode(body);
        final Stream<List<int>> stream =
            Stream<List<int>>.fromIterable([bytes]);

        final http.StreamedResponse r = http.StreamedResponse(stream, 200);

        return r;
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
      expect(await capt.finalize().bytesToString(), r'{"operationName":"ReadRepositories","variables":{"nRepositories":42},"query":"  query ReadRepositories($nRepositories: Int!) {\n    viewer {\n      repositories(last: $nRepositories) {\n        nodes {\n          __typename\n          id\n          name\n          viewerHasStarred\n        }\n      }\n    }\n  }\n"}');

      expect(r.errors, isNull);
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
//    test('failed query because of because of invalid response', {});
  });
  group('mutation', () {
    test('successful mutation', () async {
      final MutationOptions _options = MutationOptions(
        document: addStar,
        variables: <String, dynamic>{
          'nRepositories': 38,
        },
      );
      when(
        mockHttpClient.send(any)
      ).thenAnswer((Invocation a) async {
        const String body =
            '{"data":{"action":{"starrable":{"viewerHasStarred":true}}}}';

        final List<int> bytes = utf8.encode(body);
        final Stream<List<int>> stream =
        Stream<List<int>>.fromIterable(<List<int>>[bytes]);

        final http.StreamedResponse r = http.StreamedResponse(stream, 200);
        return r;
      });

      final QueryResult r = await graphQLClientClient.mutate(_options);

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
      expect(await capt.finalize().bytesToString(), r'{"operationName":"AddStar","variables":{"nRepositories":38},"query":"  mutation AddStar($starrableId: ID!) {\n    action: addStar(input: {starrableId: $starrableId}) {\n      starrable {\n        viewerHasStarred\n      }\n    }\n  }\n"}');

      expect(r.errors, isNull);
      expect(r.data, isNotNull);
      final bool viewerHasStarred =
          r.data['action']['starrable']['viewerHasStarred'] as bool;
      expect(viewerHasStarred, true);
    });
  });
  group('upload', () {
    const String uploadMutation = r'''
    mutation($files: [Upload!]!) {
      multipleUpload(files: $files) {
        id
        filename
        mimetype
        path
      }
    }

    ''';
//    test('upload success', () async {
//      final List<File> files = <String>['sample_upload.bin', 'sample_upload.img']
//          .map((String fileName) => join(
//                dirname(Platform.script.path),
//                'test',
//              ))
//          .map((String filePath) => File(filePath))
//          .toList();
//
//      final MutationOptions _options = MutationOptions(
//        document: uploadMutation,
//        variables: <String, dynamic>{
//          'files': files,
//        },
//      );
//
//
//      final QueryResult r = await graphQLClientClient.mutate(_options);
//      expect(r.errors, isNull);
//      expect(r.data, isNotNull);
//      final bool viewerHasStarred =
//      r.data['action']['starrable']['viewerHasStarred'] as bool;
//      expect(viewerHasStarred, true);
//    });
  });
}
