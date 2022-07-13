import 'package:flutter/material.dart';
import 'package:graphql_chat/view/home_view.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:trash_themes/themes.dart';

Future<void> main() async {
  // We're using HiveStore for persistence,
  // so we need to initialize Hive.
  await initHiveForFlutter();
  final HttpLink httpLink = HttpLink(
    defaultHeaders: {
      "Accept": "application/json",
      "Access-Control_Allow_Origin": "*",
    },
    'http://127.0.0.1:9000/graphql',
  );
  var wsLink = WebSocketLink(
    'ws://127.0.0.1:9000/graphql',
    config: const SocketClientConfig(
      inactivityTimeout: Duration(seconds: 40),
    ),
    subProtocol: SocketSubProtocol.graphqlTransportWs,
  );
  final Link link = httpLink.split(
    (request) => request.isSubscription,
    wsLink,
    httpLink,
  );
  ValueNotifier<GraphQLClient> client = ValueNotifier(
    GraphQLClient(
      link: httpLink,
      // The default store is the InMemoryStore, which does NOT persist to disk
      cache: GraphQLCache(store: HiveStore()),
    ),
  );
  runApp(ChatApp(client: client));
}

class ChatApp extends StatelessWidget {
  final ValueNotifier<GraphQLClient> client;

  const ChatApp({Key? key, required this.client}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: client,
      child: MaterialApp(
        title: 'GraphQL flutter',
        theme: DraculaTheme().makeDarkTheme(context: context),
        home: const HomeView(),
      ),
    );
  }
}
