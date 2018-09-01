import 'package:flutter/widgets.dart';

import 'package:graphql_flutter/src/graphql_client.dart';
import 'package:graphql_flutter/src/core/observable_query.dart';
import 'package:graphql_flutter/src/core/query_options.dart';
import 'package:graphql_flutter/src/core/query_result.dart';

import 'package:graphql_flutter/src/widgets/graphql_provider.dart';

typedef RunMutation = void Function(Map<String, dynamic> variables);
typedef MutationBuilder = Widget Function(
  RunMutation runMutation,
  QueryResult result,
);
typedef void OnMutationCompleted(QueryResult result);

class Mutation extends StatefulWidget {
  final MutationOptions options;
  final MutationBuilder builder;
  final OnMutationCompleted onCompleted;

  Mutation({
    final Key key,
    @required this.options,
    @required this.builder,
    this.onCompleted,
  }) : super(key: key);

  @override
  MutationState createState() => MutationState();
}

class MutationState extends State<Mutation> {
  GraphQLClient client;
  ObservableQuery observableQuery;

  void runMutation(Map<String, dynamic> variables) {
    observableQuery.setVariables(variables);
    observableQuery.schedule();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    observableQuery.close();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    /// Gets the client from the closest wrapping [GraphqlProvider].
    client = GraphQLProvider.of(context).value;

    WatchQueryOptions options = WatchQueryOptions(
      document: widget.options.document,
      variables: widget.options.variables,
      fetchPolicy: widget.options.fetchPolicy,
      errorPolicy: widget.options.errorPolicy,
      fetchResults: false,
    );

    observableQuery = client.watchQuery(options);

    super.didChangeDependencies();
  }

  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: observableQuery.stream,
      initialData: QueryResult(
        loading: true,
      ),
      builder: (
        BuildContext buildContext,
        AsyncSnapshot<QueryResult> snapshot,
      ) {
        return widget.builder(
          runMutation,
          snapshot.data,
        );
      },
    );
  }
}
