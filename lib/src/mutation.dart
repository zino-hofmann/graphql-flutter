import 'package:flutter/widgets.dart';

import './client.dart';

typedef void RunMutation(Map variables);

typedef Widget MutationBuilder(
  RunMutation mutation, {
  @required bool loading,
  Map data,
  String error,
});

class Mutation extends StatefulWidget {
  Mutation(
    this.mutation, {
    Key key,
    @required this.builder,
  }) : super(key: key);

  final String mutation;
  final MutationBuilder builder;

  @override
  MutationState createState() => new MutationState();
}

class MutationState extends State<Mutation> {
  bool loading = false;
  Map data = {};
  String error = '';

  void runMutation(Map variables) async {
    setState(() {
      loading = true;
      error = '';
      data = {};
    });

    try {
      final result = await client.execute(
        query: widget.mutation,
        variables: variables,
      );

      setState(() {
        loading = false;
        data = result;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = 'GQL ERROR';
      });

      // TODO: Handle error
      print(e);
    }
  }

  Widget build(BuildContext context) {
    return widget.builder(
      runMutation,
      loading: loading,
      error: error,
      data: data,
    );
  }
}
