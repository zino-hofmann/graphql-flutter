import 'package:gql/ast.dart';
import 'package:graphql/src/core/query_options.dart';
import 'package:graphql/src/core/query_result.dart';
import 'package:graphql/src/graphql_client.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

main() {
  group('GraphQLClient Mock Test |', () {
    GraphQLClient client;

    setUpAll(() {
      client = _MockClient();
    });

    test('Check for equal MutationOptions', () {
      final email = "test@user.com";
      final password = "password";
      final a = MutationOptions(
        documentNode: document,
        variables: {'email': email, 'password': password},
      );
      final b = MutationOptions(
        documentNode: document,
        variables: {'email': email, 'password': password},
      );
      expect(a, b);
    });

    test('Login Mutation', () async {
      final email = "test@user.com";
      final password = "password";
      final options = MutationOptions(
        documentNode: document,
        variables: {'email': email, 'password': password},
      );
      when(client.mutate(options))
          .thenAnswer((_) => Future.value(loginResponse));
      final res = await client.mutate(
        MutationOptions(
          documentNode: document,
          variables: {'email': email, 'password': password},
        ),
      );
      expect(res, loginResponse);
    });
  });
}

class _MockClient extends Mock implements GraphQLClient {}

final loginResponse = QueryResult(
  data: {
    "login": {
      "errors": null,
      "expiresAt": 1595243976060,
      "status": 200,
      "token":
          "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE1OTUyNDM5NzYsInN1YiI6MX0.D4x4I2I_gvJJFh-Endbx2iamiyJjQqyeUbIZS1riF5E",
      "user": {
        "email": "test@user.com",
        "firstName": "Leslie",
        "id": 1,
        "lastName": "User",
        "name": "Test User",
      }
    }
  },
);

const loginAST = OperationDefinitionNode(
    type: OperationType.mutation,
    name: NameNode(value: 'login'),
    variableDefinitions: [
      VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'email')),
          type: NamedTypeNode(name: NameNode(value: 'String'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: []),
      VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'password')),
          type: NamedTypeNode(name: NameNode(value: 'String'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [])
    ],
    directives: [],
    selectionSet: SelectionSetNode(selections: [
      FieldNode(
          name: NameNode(value: 'login'),
          alias: null,
          arguments: [
            ArgumentNode(
                name: NameNode(value: 'email'),
                value: VariableNode(name: NameNode(value: 'email'))),
            ArgumentNode(
                name: NameNode(value: 'password'),
                value: VariableNode(name: NameNode(value: 'password')))
          ],
          directives: [],
          selectionSet: SelectionSetNode(selections: [
            FieldNode(
                name: NameNode(value: 'errors'),
                alias: null,
                arguments: [],
                directives: [],
                selectionSet: SelectionSetNode(selections: [
                  FieldNode(
                      name: NameNode(value: 'message'),
                      alias: null,
                      arguments: [],
                      directives: [],
                      selectionSet: null),
                  FieldNode(
                      name: NameNode(value: 'property'),
                      alias: null,
                      arguments: [],
                      directives: [],
                      selectionSet: null)
                ])),
            FieldNode(
                name: NameNode(value: 'expiresAt'),
                alias: null,
                arguments: [],
                directives: [],
                selectionSet: null),
            FieldNode(
                name: NameNode(value: 'status'),
                alias: null,
                arguments: [],
                directives: [],
                selectionSet: null),
            FieldNode(
                name: NameNode(value: 'token'),
                alias: null,
                arguments: [],
                directives: [],
                selectionSet: null),
            FieldNode(
                name: NameNode(value: 'user'),
                alias: null,
                arguments: [],
                directives: [],
                selectionSet: SelectionSetNode(selections: [
                  FieldNode(
                      name: NameNode(value: 'email'),
                      alias: null,
                      arguments: [],
                      directives: [],
                      selectionSet: null),
                  FieldNode(
                      name: NameNode(value: 'firstName'),
                      alias: null,
                      arguments: [],
                      directives: [],
                      selectionSet: null),
                  FieldNode(
                      name: NameNode(value: 'id'),
                      alias: null,
                      arguments: [],
                      directives: [],
                      selectionSet: null),
                  FieldNode(
                      name: NameNode(value: 'lastName'),
                      alias: null,
                      arguments: [],
                      directives: [],
                      selectionSet: null),
                  FieldNode(
                      name: NameNode(value: 'name'),
                      alias: null,
                      arguments: [],
                      directives: [],
                      selectionSet: null),
                ]))
          ]))
    ]));
const document = DocumentNode(definitions: [loginAST]);
