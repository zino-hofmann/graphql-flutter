/// Integration test regarding the graphq_flutter widget
///
/// In this particular test suite we implement a battery of test
/// to make sure that all the operation on a widget are done
/// correctly.
///
/// More precise in this file all the test are regarding the web socket and
/// the subscription.
///
/// Trying to reproduce the problems caused by the following issue
/// - Subscription not receive update
///    - https://github.com/zino-hofmann/graphql-flutter/issues/1163
///    - https://github.com/zino-hofmann/graphql-flutter/issues/1162
///
/// author: https://github.com/vincenzopalazzo
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logger/logger.dart';
import 'clients/ClientProvider.dart';
import 'model/chat_app_model.dart';
import 'widget/MockAppView.dart' as app;
import 'widget/list_view_query.dart';
import 'widget/list_view_subscription.dart';

/// Configure the test to check if the ws `GraphQLProtocol.graphqlTransportWs` receive
/// update correctly.
Future<void> configureTestForSimpleSubscriptionUpdate(dynamic tester) async {
  var logger = Logger();

  /// build a simple client with a in memory
  var client = ClientProvider().chatAppClient();
  app.main(client: client, childToTest: ListChatSubscriptionView());
  await tester.pumpAndSettle();
  var listChats = await client.query(QueryOptions(document: gql(r"""
   query {
        getChats {
          __typename
          id
          description
          name
        }
      }
  """)));
  logger.d("Exception: ${listChats.exception}");
  expect(listChats.hasException, isFalse);
  logger.i("Chats contains inside the server: ${listChats.data}");
  var chatName = "graphql_flutter test chat ${DateTime.now()}";
  var description = "graphql_flutter integration test in ${DateTime.now()}";
  await client.mutate(MutationOptions(document: gql(r"""
   mutation CreateChat($description: String!, $name: String!){
      createChat(description: $description, name: $name) {
        __typename
        name
      }
    }
  """), variables: {
    "name": chatName,
    "description": description,
  }));

  //find new item in the list
  await tester.pump(const Duration(seconds: 10));
  final subscriptionItem = find.text(chatName);
  expect(subscriptionItem, findsOneWidget);
}

/// Configure the test to check if we receive all the element from the graphql
Future<void> configureTestForSimpleQuery(dynamic tester) async {
  var logger = Logger();

  /// build a simple client with a in memory
  var client = ClientProvider().chatAppClient();
  app.main(client: client, childToTest: ListChatQueryView());
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 10));
  var listChats = await client.query(QueryOptions(
      document: gql(r"""
   query {
        getChats {
          __typename
          id
          description
          name
        }
      }
  """),
      parserFn: (Map<String, dynamic> json) {
        var rawList = List.of(json["getChats"] as List<dynamic>);
        return rawList
            .map((jsonChat) => Chat.fromJSON(jsonChat as Map<String, dynamic>))
            .toList();
      }));
  logger.d("Exception: ${listChats.exception}");
  expect(listChats.hasException, isFalse);
  logger.i("Chats contains inside the server: ${listChats.data}");
  var chats = listChats.parsedData as List<Chat>;
  for (var chat in chats) {
    //find new item in the list
    final subscriptionItem = find.text(chat.name);

    /// Finds not only one but more than one
    expect(subscriptionItem, findsWidgets);
  }
}

class CustomBindings extends AutomatedTestWidgetsFlutterBinding {
  @override
  bool get overrideHttpClient => false;
}

void main() {
  //CustomBindings();
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Run simple query and check if we find all the element displayed',
      configureTestForSimpleQuery);
  testWidgets('Run simple subscription and wait the result of the update',
      configureTestForSimpleSubscriptionUpdate);
}
