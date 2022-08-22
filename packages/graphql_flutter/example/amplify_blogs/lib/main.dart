import 'dart:convert';

import 'package:amplify_blogs/view/home/home_view.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:trash_themes/themes/dracula.dart';
import 'package:gql/language.dart';

String toBase64(Map data) => base64.encode(utf8.encode(jsonEncode(data)));

class AppSyncRequest extends RequestSerializer {
  Map<String, dynamic> authHeader;

  AppSyncRequest({
    required this.authHeader,
  });

  @override
  Map<String, dynamic> serializeRequest(Request request) => {
        "data": jsonEncode({
          "query": printNode(request.operation.document),
          "variables": request.variables,
        }),
        "extensions": {
          "authorization": authHeader,
        }
      };
}

Future<void> main() async {
  await initHiveForFlutter();

  // AWS docs about the API link and the tokens
  // https://docs.aws.amazon.com/appsync/latest/devguide/real-time-websocket-client.html#handshake-details-to-establish-the-websocket-connection
  final HttpLink httpLink = HttpLink(
    'https://d2wp6jvgffhoblw4qzgwdjp6hm.appsync-api.eu-west-1.amazonaws.com/graphql',
    defaultHeaders: {
      "Accept": "application/json",
      'x-api-key': '<TOKEN>',
    },
  );

  var authHeader = {
    "x-api-key": "da2-5sg7vxdr2nd3vk3gidb2tdygu4",
    "host": "<TOKEN>",
  };

  var encodedHeader = toBase64(authHeader);
  var wsLink = WebSocketLink(
    'wss://d2wp6jvgffhoblw4qzgwdjp6hm.appsync-realtime-api.eu-west-1.amazonaws.com/graphql?header=$encodedHeader&payload=e30=',
    config: SocketClientConfig(
      serializer: AppSyncRequest(authHeader: authHeader),
      headers: authHeader,
      inactivityTimeout: const Duration(seconds: 40),
    ),
    subProtocol: GraphQLProtocol.graphqlWs,
  );

  final Link link = Link.split(
    (request) => request.isSubscription,
    wsLink,
    httpLink,
  );

  ValueNotifier<GraphQLClient> client = ValueNotifier(
    GraphQLClient(
      link: link,
      // The default store is the InMemoryStore, which does NOT persist to disk
      cache: GraphQLCache(store: HiveStore()),
    ),
  );
  runApp(AmplifyBlogsApp(client: client));
}

class AmplifyBlogsApp extends StatelessWidget {
  final ValueNotifier<GraphQLClient> client;

  const AmplifyBlogsApp({Key? key, required this.client}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: client,
      child: MaterialApp(
        title: 'GraphQL Flutter Blogs',
        theme: DraculaTheme().makeDarkTheme(context: context),
        home: HomeView(title: 'Flutter Demo Home Page', client: client),
      ),
    );
  }
}
