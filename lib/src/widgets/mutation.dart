import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:graphql_flutter/src/graphql_client.dart';
import 'package:graphql_flutter/src/widgets/graphql_provider.dart';

typedef Future<void> RunMutation(Map<String, dynamic> variables);
typedef void OnMutationCompleted(Map<String, dynamic> data);
typedef Widget MutationBuilder(
  RunMutation mutation, {
  @required bool loading,
  Map<String, dynamic> data,
  Exception error,
});

class Mutation extends StatefulWidget {
  Mutation(
    this.mutation, {
    final Key key,
    @required this.builder,
    this.onCompleted,
  }) : super(key: key);

  final String mutation;
  final MutationBuilder builder;
  final OnMutationCompleted onCompleted;

  @override
  MutationState createState() => MutationState();
}

class MutationState extends State<Mutation> {
  GraphQLClient client;

  @override
  void didChangeDependencies() {
    /// Gets the client from the closest wrapping [GraphqlProvider].
    client = GraphQLProvider.of(context).value;

    super.didChangeDependencies();
  }

  Widget build(BuildContext context) {
    return StreamBuilder(steam: builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {

    },);
  }
}
