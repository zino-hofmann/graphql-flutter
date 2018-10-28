import 'dart:async';

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

/// Builds a [Mutation] widget based on the a given set of [MutationOptions]
/// that streams [QueryResult]s into the [QueryBuilder].
class Mutation extends StatefulWidget {
  final MutationOptions options;
  final MutationBuilder builder;
  final OnMutationCompleted onCompleted;

  const Mutation({
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
  StreamSubscription<QueryResult> onCompleteSubscription;

  void runMutation(Map<String, dynamic> variables) {
    observableQuery.setVariables(variables);

    if (widget.onCompleted != null) {
      onCompleteSubscription = observableQuery.stream.listen(
        (QueryResult result) {
          if (!result.loading) {
            widget.onCompleted(result);
            onCompleteSubscription.cancel();
          }
        },
      );
    }

    observableQuery.controller.add(
      QueryResult(
        loading: true,
      ),
    );

    observableQuery.fetchResults();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    onCompleteSubscription?.cancel();
    observableQuery?.close();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    /// Gets the client from the closest wrapping [GraphqlProvider].
    client = GraphQLProvider.of(context).value;
    assert(client != null);

    final WatchQueryOptions options = WatchQueryOptions(
      document: widget.options.document,
      variables: widget.options.variables,
      fetchPolicy: widget.options.fetchPolicy,
      errorPolicy: widget.options.errorPolicy,
      fetchResults: false,
      context: widget.options.context,
    );

    bool shouldCreateNewObservable = true;

    if (observableQuery != null) {
      if (observableQuery.options.areEqualTo(options)) {
        shouldCreateNewObservable = false;
      }

      observableQuery.close();
    }

    if (shouldCreateNewObservable) {
      observableQuery = client.watchQuery(options);
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QueryResult>(
      initialData: QueryResult(
        loading: false,
      ),
      stream: observableQuery.stream,
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
