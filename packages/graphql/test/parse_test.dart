import 'package:graphql/client.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'helpers.dart' as helpers;

main() {
  late helpers.MockLink link;
  late GraphQLClient client;

  setUp(() {
    link = helpers.MockLink();

    client = GraphQLClient(
      cache: helpers.getTestCache(),
      link: link,
    );
  });

  test("Test can parse", () async {
    const createProfileMutation = r'''
  mutation createProfile(
      $firstname: String!, 
      $lastname: String!, 

    ){
      action: createProfile(createProfileInput: 
      {
        firstname: $firstname,
        lastname: $lastname, 

        })
        {
          firstname,
          lastname,
        }
  }
''';
    final mutationResponseWithNewName = Response(
      data: <String, dynamic>{
        '__typename': 'Mutation',
        'action': {
          '__typename': 'Action',
          'firstname': "Bob",
          'lastname': 'Bobsen'
        }
      },
    );
    when(
      link.request(any),
    ).thenAnswer(
      (_) => Stream.fromIterable(
        [mutationResponseWithNewName],
      ),
    );
    final QueryResult response = await client.mutate(MutationOptions(
        document: gql(createProfileMutation),
        variables: {'firstname': 'Lars', 'lastname': 'Larsen'}));

    expect(response.data!['action']['firstname'], "Bob");
    expect(response.exception, null);
  });
}
