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
  bool _observableIsStale;
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

  void _replaceStaleObservable() {
    if (_observableIsStale) {
      observableQuery.close();
      observableQuery = client.watchQuery(_options);
      _observableIsStale = false;
    }
  }

  void runMutation(Map<String, dynamic> variables) {
    _replaceStaleObservable();
    observableQuery.setVariables(variables);

    if (widget.onCompleted != null || widget.update != null) {
      onCompleteSubscription =
          observableQuery.stream.listen((QueryResult result) {
        if (!result.loading) {
          if (widget.onCompleted != null) {
            widget.onCompleted(result);
          }
          if (widget.update != null) {
            widget.update(client.cache, result);
          }
          onCompleteSubscription.cancel();
        }
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
    onCompleteSubscription?.cancel();
    observableQuery.close();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    /// Gets the client from the closest wrapping [GraphqlProvider].
    final GraphQLClient newClient = GraphQLProvider.of(context).value;
    assert(newClient != null);

    if (observableQuery != null &&
        observableQuery.isCurrentlyPolling &&
        newClient != client) {
      client = newClient;
      _observableIsStale = true;
    } else if (client != newClient) {
      client = newClient;
      _observableIsStale = false;
      observableQuery = client.watchQuery(_options);
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
