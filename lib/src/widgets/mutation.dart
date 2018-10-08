import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:graphql_flutter/src/graphql_client.dart';
import 'package:graphql_flutter/src/core/observable_query.dart';
import 'package:graphql_flutter/src/core/query_options.dart';
import 'package:graphql_flutter/src/core/query_result.dart';
import 'package:graphql_flutter/src/cache/cache.dart';

import 'package:graphql_flutter/src/widgets/graphql_provider.dart';

typedef RunMutation = void Function(Map<String, dynamic> variables);
typedef MutationBuilder = Widget Function(
  RunMutation runMutation,
  QueryResult result,
);

typedef void OnMutationCompleted(QueryResult result);
typedef void OnMutationUpdate(Cache cache, QueryResult result);

/// Builds a [Mutation] widget based on the a given set of [MutationOptions]
/// that streams [QueryResult]s into the [QueryBuilder].
class Mutation extends StatefulWidget {
  final MutationOptions options;
  final MutationBuilder builder;
  final OnMutationCompleted onCompleted;
  final OnMutationUpdate update;

  const Mutation({
    final Key key,
    @required this.options,
    @required this.builder,
    this.onCompleted,
    this.update,
  }) : super(key: key);

  @override
  MutationState createState() => MutationState();
}

class MutationState extends State<Mutation> {
  GraphQLClient client;
  ObservableQuery observableQuery;
  StreamSubscription<QueryResult> onCompleteSubscription;

  WatchQueryOptions get _options => WatchQueryOptions(
        document: widget.options.document,
        variables: widget.options.variables,
        fetchPolicy: widget.options.fetchPolicy,
        errorPolicy: widget.options.errorPolicy,
        fetchResults: false,
        context: widget.options.context,
      );

  void _cleanup() {
    onCompleteSubscription?.cancel();
    observableQuery?.close();
  }

  void _newMutation(Map<String, dynamic> variables) {
    _cleanup();
    observableQuery = client.watchQuery(_options);
  }

  void runMutation(Map<String, dynamic> variables) {
    _newMutation(variables);

    if (widget.onCompleted != null || widget.update != null) {
      onCompleteSubscription =
          observableQuery.stream.listen((QueryResult result) {
        if (widget.onCompleted != null) {
          widget.onCompleted(result);
        }
        if (widget.update != null) {
          widget.update(client.cache, result);
        }
        onCompleteSubscription.cancel();
      });
    }

    observableQuery.controller.add(
      QueryResult(
        loading: true,
      ),
    );

    observableQuery.fetchResults();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    /// Gets the client from the closest wrapping [GraphqlProvider].
    client = GraphQLProvider.of(context).value;
    assert(client != null);
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
