import 'dart:convert';
import 'dart:io' show File, Platform;
import 'dart:typed_data' show Uint8List;

import 'package:path/path.dart' show dirname, join;
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
  group('simple json', () {
    setUp(() {
      mockHttpClient = MockHttpClient();

      httpLink = HttpLink(
          uri: 'https://api.github.com/graphql', httpClient: mockHttpClient);

      authLink = AuthLink(
        getToken: () async => 'Bearer my-special-bearer-token',
      );

      link = authLink.concat(httpLink as Link);

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
              Stream<List<int>>.fromIterable(<List<int>>[bytes]);

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
        expect(await capt.finalize().bytesToString(),
            r'{"operationName":"ReadRepositories","variables":{"nRepositories":42},"query":"  query ReadRepositories($nRepositories: Int!) {\n    viewer {\n      repositories(last: $nRepositories) {\n        nodes {\n          __typename\n          id\n          name\n          viewerHasStarred\n        }\n      }\n    }\n  }\n"}');

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
          document: addStar,
          variables: <String, dynamic>{
            'nRepositories': 38,
          },
        );
        when(mockHttpClient.send(any)).thenAnswer((Invocation a) async {
          const String body =
              '{"data":{"action":{"starrable":{"viewerHasStarred":true}}}}';

          final List<int> bytes = utf8.encode(body);
          final Stream<List<int>> stream =
              Stream<List<int>>.fromIterable(<List<int>>[bytes]);

          final http.StreamedResponse r = http.StreamedResponse(stream, 200);
          return r;
        });

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
            r'{"operationName":"AddStar","variables":{"nRepositories":38},"query":"  mutation AddStar($starrableId: ID!) {\n    action: addStar(input: {starrableId: $starrableId}) {\n      starrable {\n        viewerHasStarred\n      }\n    }\n  }\n"}');

        expect(response.errors, isNull);
        expect(response.data, isNotNull);
        final bool viewerHasStarred =
            response.data['action']['starrable']['viewerHasStarred'] as bool;
        expect(viewerHasStarred, true);
      });
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

    setUp(() {
      mockHttpClient = MockHttpClient();

      httpLink = HttpLink(
          uri: 'http://localhost:3001/graphql', httpClient: mockHttpClient);

      authLink = AuthLink(
        getToken: () async => 'Bearer my-special-bearer-token',
      );

      link = authLink.concat(httpLink as Link);

      graphQLClientClient = GraphQLClient(
        cache: NormalizedInMemoryCache(
          dataIdFromObject: typenameDataIdFromObject,
        ),
        link: link,
      );
    });

    test('upload success', () async {
      Future<void> expectUploadBody(http.ByteStream bodyBytesStream,
          String boundary, List<File> files) async {
        final List<Function> expectContinuationList = (() {
          int i = 0;
          return <Function>[
            // ExpectString
            (Uint8List actual, String expected) => expect(
                String.fromCharCodes(actual.sublist(i, i += expected.length)),
                expected),
            // ExpectBytes
            (Uint8List actual, Uint8List expected) =>
                expect(actual.sublist(i, i += expected.length), expected),
            // Expect final length
            (int expectedLength) => expect(i, expectedLength),
          ];
        })();
        final Function expectContinuationString = expectContinuationList[0];
        final Function expectContinuationBytes = expectContinuationList[1];
        final Function expectContinuationLength = expectContinuationList[2];
        final Uint8List bodyBytes = await bodyBytesStream.toBytes();
        expectContinuationString(bodyBytes, '--');
        expectContinuationString(bodyBytes, boundary);
        expectContinuationString(bodyBytes,
            '\r\ncontent-disposition: form-data; name="operations"\r\n\r\n');
        // operationName of unamed operations is "UNNAMED/" +  document.hashCode.toString()
        expectContinuationString(bodyBytes,
            r'{"operationName":"UNNAMED/596708007","variables":{"files":[null,null]},"query":"    mutation($files: [Upload!]!) {\n      multipleUpload(files: $files) {\n        id\n        filename\n        mimetype\n        path\n      }\n    }\n    "}');
        expectContinuationString(bodyBytes, '\r\n--');
        expectContinuationString(bodyBytes, boundary);
        expectContinuationString(bodyBytes,
            '\r\ncontent-disposition: form-data; name="map"\r\n\r\n{"0":["variables.files.0"],"1":["variables.files.1"]}');
        expectContinuationString(bodyBytes, '\r\n--');
        expectContinuationString(bodyBytes, boundary);
        expectContinuationString(bodyBytes,
            '\r\ncontent-type: image/jpeg\r\ncontent-disposition: form-data; name="0"; filename="sample_upload.jpg"\r\n\r\n');
        expectContinuationBytes(bodyBytes, await files[0].readAsBytes());
        expectContinuationString(bodyBytes, '\r\n--');
        expectContinuationString(bodyBytes, boundary);
        expectContinuationString(bodyBytes,
            '\r\ncontent-type: video/quicktime\r\ncontent-disposition: form-data; name="1"; filename="sample_upload.mov"\r\n\r\n');
        expectContinuationBytes(bodyBytes, await files[1].readAsBytes());
        expectContinuationString(bodyBytes, '\r\n--');
        expectContinuationString(bodyBytes, boundary);
        expectContinuationString(bodyBytes, '--\r\n');
        expectContinuationLength(bodyBytes.lengthInBytes);
      }

      http.ByteStream bodyBytes;
      when(mockHttpClient.send(any)).thenAnswer((Invocation a) async {
        bodyBytes = (a.positionalArguments[0] as http.BaseRequest).finalize();
        const String body = r'''
{
  "data": {
    "multipleUpload": [
      {
        "id": "r1odc4PAz",
        "filename": "sample_upload.jpg",
        "mimetype": "image/jpeg",
        "path": "./uploads/r1odc4PAz-sample_upload.jpg"
      },
      {
        "id": "5Ea18qlMur",
        "filename": "sample_upload.mov",
        "mimetype": "video/quicktime",
        "path": "./uploads/5Ea18qlMur-sample_upload.mov"
      }
    ]
  }
}
        ''';

        final List<int> bytes = utf8.encode(body);
        final Stream<List<int>> stream =
            Stream<List<int>>.fromIterable(<List<int>>[bytes]);

        final http.StreamedResponse r = http.StreamedResponse(stream, 200);
        return r;
      });

      final String basePath = dirname(Platform.script.path);
      final String realPath =
          basePath.endsWith('test') ? basePath : join(basePath, 'test');
      final List<File> files =
          <String>['sample_upload.jpg', 'sample_upload.mov']
              .map((String fileName) => join(
                    realPath,
                    fileName,
                  ))
              .map((String filePath) => File(filePath))
              .toList();

      final MutationOptions _options = MutationOptions(
        document: uploadMutation,
        variables: <String, dynamic>{
          'files': files,
        },
      );
      final QueryResult r = await graphQLClientClient.mutate(_options);

      expect(r.errors, isNull);
      expect(r.data, isNotNull);

      final http.MultipartRequest request =
          verify(mockHttpClient.send(captureAny)).captured.first
              as http.MultipartRequest;
      expect(request.method, 'post');
      expect(request.url.toString(), 'http://localhost:3001/graphql');
      expect(request.headers['accept'], '*/*');
      expect(
          request.headers['Authorization'], 'Bearer my-special-bearer-token');
      final List<String> contentTypeStringSplit =
          request.headers['content-type'].split('; boundary=');
      expect(contentTypeStringSplit[0], 'multipart/form-data');
      await expectUploadBody(bodyBytes, contentTypeStringSplit[1], files);

      final List<Map<String, dynamic>> multipleUpload =
          (r.data['multipleUpload'] as List<dynamic>)
              .cast<Map<String, dynamic>>();

      expect(multipleUpload, <Map<String, String>>[
        <String, String>{
          'id': 'r1odc4PAz',
          'filename': 'sample_upload.jpg',
          'mimetype': 'image/jpeg',
          'path': './uploads/r1odc4PAz-sample_upload.jpg'
        },
        <String, String>{
          'id': '5Ea18qlMur',
          'filename': 'sample_upload.mov',
          'mimetype': 'video/quicktime',
          'path': './uploads/5Ea18qlMur-sample_upload.mov'
        },
      ]);
    });

//    test('upload fail error response', () {
//      const String responseBody =
//          r'{"errors":[{"message":"Variable \"$files\" of required type \"[Upload!]!\" was not provided.","locations":[{"line":1,"column":14}],"extensions":{"code":"INTERNAL_SERVER_ERROR","exception":{"stacktrace":["GraphQLError: Variable \"$files\" of required type \"[Upload!]!\" was not provided.","    at getVariableValues (/Users/truongsinh/Dev/flutter/graphql-flutter/example/server/api/node_modules/graphql/execution/values.js:76:21)","    at buildExecutionContext (/Users/truongsinh/Dev/flutter/graphql-flutter/example/server/api/node_modules/graphql/execution/execute.js:196:63)","    at executeImpl (/Users/truongsinh/Dev/flutter/graphql-flutter/example/server/api/node_modules/graphql/execution/execute.js:70:20)","    at Object.execute (/Users/truongsinh/Dev/flutter/graphql-flutter/example/server/api/node_modules/graphql/execution/execute.js:62:35)","    at /Users/truongsinh/Dev/flutter/graphql-flutter/example/server/api/node_modules/apollo-server-core/dist/requestPipeline.js:195:36","    at Generator.next (<anonymous>)","    at /Users/truongsinh/Dev/flutter/graphql-flutter/example/server/api/node_modules/apollo-server-core/dist/requestPipeline.js:7:71","    at new Promise (<anonymous>)","    at __awaiter (/Users/truongsinh/Dev/flutter/graphql-flutter/example/server/api/node_modules/apollo-server-core/dist/requestPipeline.js:3:12)","    at execute (/Users/truongsinh/Dev/flutter/graphql-flutter/example/server/api/node_modules/apollo-server-core/dist/requestPipeline.js:179:20)","    at Object.<anonymous> (/Users/truongsinh/Dev/flutter/graphql-flutter/example/server/api/node_modules/apollo-server-core/dist/requestPipeline.js:131:35)","    at Generator.next (<anonymous>)","    at fulfilled (/Users/truongsinh/Dev/flutter/graphql-flutter/example/server/api/node_modules/apollo-server-core/dist/requestPipeline.js:4:58)","    at process._tickCallback (internal/process/next_tick.js:68:7)"]}}}]';
//      const int statusCode = 400;
//    });
  });
}
