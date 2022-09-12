import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

void main({GraphQLClient? client, Widget? childToTest}) => runApp(
    MockAppView(client: ValueNotifier(client!), childToTest: childToTest!));

class MockAppView extends StatelessWidget {
  final ValueNotifier<GraphQLClient> client;
  final Widget childToTest;

  MockAppView({required this.client, required this.childToTest});

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: client,
      child: MaterialApp(
        title: 'Mock App',
        home: childToTest,
      ),
    );
  }
}
