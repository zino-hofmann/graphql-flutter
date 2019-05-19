import 'dart:convert';
import 'dart:io' show File, Directory;
import 'dart:typed_data' show Uint8List;

import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

import 'package:graphql/client.dart';

import './helpers.dart';

class MockHttpClient extends Mock implements http.Client {}

NormalizedInMemoryCache getTestCache() => NormalizedInMemoryCache(
      dataIdFromObject: typenameDataIdFromObject,
      storageProvider: () => Directory.systemTemp.createTempSync('file_test_'),
    );

void main() {
  HttpLink httpLink;
  AuthLink authLink;
  Link link;
  GraphQLClient graphQLClientClient;
  MockHttpClient mockHttpClient;

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
        cache: getTestCache(),
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
            r'{"operationName":null,"variables":{"files":[null,null]},"query":"    mutation($files: [Upload!]!) {\n      multipleUpload(files: $files) {\n        id\n        filename\n        mimetype\n        path\n      }\n    }\n    "}');
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
        return simpleResponse(body: r'''
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
        ''');
      });

      final List<File> files = <String>[
        'sample_upload.jpg',
        'sample_upload.mov'
      ].map((String fileName) => tempFile(fileName)).toList();

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

    //test('upload fail error response', () {
    //  const String responseBody = json.encode({
    //    "errors":[
    //      {
    //        "message": r'Variable "$files" of required type "[Upload!]!" was not provided.',
    //        "locations": [{ "line" :1, "column" :14 }],
    //        "extensions": {
    //          "code": "INTERNAL_SERVER_ERROR",
    //          "exception": {
    //             "stacktrace": [ r'GraphQLError: Variable "$files" of required type "[Upload!]!" was not provided.', ... ]
    //          }
    //        }
    //      }
    //    ]
    //  });
    //  const int statusCode = 400;
    //});
  });
}
