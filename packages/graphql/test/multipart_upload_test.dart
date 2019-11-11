import 'package:gql/language.dart';
import 'package:http_parser/http_parser.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

import 'package:graphql/client.dart';

import './helpers.dart';

class MockHttpClient extends Mock implements http.Client {}

NormalizedInMemoryCache getTestCache() => NormalizedInMemoryCache(
      dataIdFromObject: typenameDataIdFromObject,
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

      link = authLink.concat(httpLink);

      graphQLClientClient = GraphQLClient(
        cache: getTestCache(),
        link: link,
      );
    });

    test('upload success', () async {
      Future<void> expectUploadBody(
          http.ByteStream bodyBytesStream, String boundary) async {
        final List<Function> expectContinuationList = (() {
          int i = 0;
          return <Function>[
            // ExpectString
            (List<int> actual, String expected) => expect(
                String.fromCharCodes(actual.sublist(i, i += expected.length)),
                expected),
            // ExpectBytes
            (List<int> actual, List<int> expected) =>
                expect(actual.sublist(i, i += expected.length), expected),
            // Expect final length
            (int expectedLength) => expect(i, expectedLength),
          ];
        })();
        final Function expectContinuationString = expectContinuationList[0];
        final Function expectContinuationBytes = expectContinuationList[1];
        final Function expectContinuationLength = expectContinuationList[2];
        final bodyBytes = await bodyBytesStream.toBytes();
        expectContinuationString(bodyBytes, '--');
        expectContinuationString(bodyBytes, boundary);
        expectContinuationString(bodyBytes,
            '\r\ncontent-disposition: form-data; name="operations"\r\n\r\n');
        // operationName of unamed operations is "UNNAMED/" +  document.hashCode.toString()
        expectContinuationString(bodyBytes,
            r'{"operationName":null,"variables":{"files":[null,null]},"query":"mutation($files: [Upload!]!) {\n  multipleUpload(files: $files) {\n    id\n    filename\n    mimetype\n    path\n  }\n}"}');
        expectContinuationString(bodyBytes, '\r\n--');
        expectContinuationString(bodyBytes, boundary);
        expectContinuationString(bodyBytes,
            '\r\ncontent-disposition: form-data; name="map"\r\n\r\n{"0":["variables.files.0"],"1":["variables.files.1"]}');
        expectContinuationString(bodyBytes, '\r\n--');
        expectContinuationString(bodyBytes, boundary);
        expectContinuationString(bodyBytes,
            '\r\ncontent-type: image/jpeg\r\ncontent-disposition: form-data; name="0"; filename="sample_upload.jpg"\r\n\r\n');
        expectContinuationBytes(bodyBytes, [0, 1, 254, 255]);
        expectContinuationString(bodyBytes, '\r\n--');
        expectContinuationString(bodyBytes, boundary);
        expectContinuationString(bodyBytes,
            '\r\ncontent-type: text/plain; charset=utf-8\r\ncontent-disposition: form-data; name="1"; filename="sample_upload.txt"\r\n\r\n');
        expectContinuationString(bodyBytes, 'just plain text');
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
        "filename": "sample_upload.txt",
        "mimetype": "text/plain",
        "path": "./uploads/5Ea18qlMur-sample_upload.txt"
      }
    ]
  }
}
        ''');
      });

      final MutationOptions _options = MutationOptions(
        documentNode: parseString(uploadMutation),
        variables: <String, dynamic>{
          'files': [
            http.MultipartFile.fromBytes(
              '',
              [0, 1, 254, 255],
              filename: 'sample_upload.jpg',
              contentType: MediaType('image', 'jpeg'),
            ),
            http.MultipartFile.fromString(
              '',
              'just plain text',
              filename: 'sample_upload.txt',
              contentType: MediaType('text', 'plain'),
            ),
          ],
        },
      );
      final QueryResult r = await graphQLClientClient.mutate(_options);

      expect(r.exception, isNull);
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
      await expectUploadBody(bodyBytes, contentTypeStringSplit[1]);

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
          'filename': 'sample_upload.txt',
          'mimetype': 'text/plain',
          'path': './uploads/5Ea18qlMur-sample_upload.txt'
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
