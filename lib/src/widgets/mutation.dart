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

  WatchQueryOptions get _options => WatchQueryOptions(
        document: widget.options.document,
        variables: widget.options.variables,
        fetchPolicy: widget.options.fetchPolicy,
        errorPolicy: widget.options.errorPolicy,
        fetchResults: false,
        context: widget.options.context,
      );

  ObservableQuery _replaceObservableQuery(Map<String, dynamic> variables) {
    // triggering a new mutation cancels previous queued callbacks
    observableQuery?.close(force: true);
    observableQuery = client.watchQuery(_options);
    observableQuery.setVariables(variables);
    return observableQuery;
  }

  OnData get update {
    if (widget.update != null) {
      void updateOnData(QueryResult result) {
        widget.update(client.cache, result);
      }

      return updateOnData;
    }
    return null;
  }

  Iterable<OnData> get callbacks {
    return <OnData>[widget.onCompleted, update].where(notNull);
  }

  void runMutation(Map<String, dynamic> variables) =>
      _replaceObservableQuery(variables)
        ..onData(callbacks) // add callbacks to observable
        ..sendLoading()
        ..fetchResults();

  @override
  void dispose() {
    observableQuery?.close(force: false);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    /// Gets the client from the closest wrapping [GraphqlProvider].
    final GraphQLClient newClient = GraphQLProvider.of(context).value;
    assert(newClient != null);

    if (client != newClient) {
      client = newClient;
      observableQuery?.close(force: false);
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QueryResult>(
      initialData: QueryResult(
        loading: false,
      ),
      stream: observableQuery?.stream,
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

bool notNull(Object any) {
  return any != null;
}
