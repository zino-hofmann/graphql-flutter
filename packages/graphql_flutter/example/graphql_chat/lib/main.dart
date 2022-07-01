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
