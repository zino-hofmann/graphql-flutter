import 'package:flutter/widgets.dart';
import 'package:graphql_flutter/src/client.dart';
import 'package:graphql_flutter/src/widgets/graphql_provider.dart';

typedef void RunMutation(Map<String, dynamic> variables);
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
  Client client;

  bool loading = false;
  Map<String, dynamic> data = {};
  Exception error;

  void runMutation(Map<String, dynamic> variables) async {
    assert(client != null);

    setState(() {
      data = {};
      error = null;
      loading = true;
    });

    try {
      final Map<String, dynamic> result = await client.query(
        query: widget.mutation,
        variables: variables,
      );

      setState(() {
        data = result;
        loading = false;
      });

      if (widget.onCompleted != null) {
        widget.onCompleted(result);
      }
    } catch (e) {
      setState(() {
        error = e;
        loading = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    /// Gets the client from the closest wrapping [GraphqlProvider].
    client = GraphqlProvider.of(context).value;

    super.didChangeDependencies();
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
