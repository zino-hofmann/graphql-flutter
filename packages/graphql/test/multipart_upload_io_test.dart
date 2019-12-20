import 'package:gql/language.dart';
@TestOn("vm")
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'dart:io' as io;

import 'package:graphql/client.dart';

import 'helpers.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  HttpLink httpLink;
  AuthLink authLink;
  Link link;
  GraphQLClient graphQLClientClient;
  MockHttpClient mockHttpClient;

  group(
    'upload',
    () {
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

        when(mockHttpClient.send(any)).thenAnswer((Invocation a) async {
          return simpleResponse(body: '{"data": {}}');
        });

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

      test(
        'upload with io.File instance deprecation warning',
        overridePrint((log) async {
          final MutationOptions _options = MutationOptions(
            documentNode: parseString(uploadMutation),
            variables: <String, dynamic>{
              'files': [
                io.File('pubspec.yaml'),
              ],
            },
          );
          final QueryResult r = await graphQLClientClient.mutate(_options);

          expect(r.exception, isNull);
          expect(r.data, isNotNull);
          expect(log, hasLength(5));
          final warningMessage = r'''
⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️ DEPRECATION WARNING ⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️

Please do not use `File` direcly anymore. Instead, use
`MultipartFile`. There's also a utitlity method to help you
`import 'package:graphql/utilities.dart' show multipartFileFrom;`

⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️ DEPRECATION WARNING ⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️⚠️️️️️️️️
    ''';
          expect(log[0], warningMessage);
          expect(log[1], warningMessage);
          expect(log[2], warningMessage);
          expect(log[3], warningMessage);
          expect(log[4], warningMessage);
        }),
      );
    },
    onPlatform: {
      "!vm": Skip("This test is only for VM"),
    },
  );
}
