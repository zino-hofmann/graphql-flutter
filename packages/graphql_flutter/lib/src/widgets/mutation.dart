import 'package:flutter/widgets.dart';

import 'package:graphql_client/graphql_client.dart';

import 'package:graphql_flutter/src/widgets/graphql_provider.dart';

typedef RunMutation = void Function(Map<String, dynamic> variables);
typedef MutationBuilder = Widget Function(
  RunMutation runMutation,
  QueryResult result,
);

typedef OnMutationCompleted = void Function(QueryResult result);
typedef OnMutationUpdate = void Function(Cache cache, QueryResult result);

/// Builds a [Mutation] widget based on the a given set of [MutationOptions]
/// that streams [QueryResult]s into the [QueryBuilder].
class Mutation extends StatefulWidget {
  const Mutation({
    final Key key,
    @required this.options,
    @required this.builder,
    this.onCompleted,
    this.update,
  }) : super(key: key);

  final MutationOptions options;
  final MutationBuilder builder;
  final OnMutationCompleted onCompleted;
  final OnMutationUpdate update;

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

  // TODO is it possible to extract shared logic into mixin
  void _initQuery() {
    client = GraphQLProvider.of(context).value;
    assert(client != null);

    observableQuery?.close();
    observableQuery = client.watchQuery(_options);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initQuery();
  }

  @override
  void didUpdateWidget(Mutation oldWidget) {
    super.didUpdateWidget(oldWidget);

    // TODO @micimize - investigate why/if this was causing issues
    if (!observableQuery.options.areEqualTo(_options)) {
      _initQuery();
    }
  }

  OnData get update {
    // fallback client in case widget has been disposed of
    final Cache cache = client.cache;
    if (widget.update != null) {
      void updateOnData(QueryResult result) {
        widget.update(client?.cache ?? cache, result);
      }

      return updateOnData;
    }
    return null;
  }

  Iterable<OnData> get callbacks {
    return <OnData>[widget.onCompleted, update]
        .where((dynamic any) => any != null);
  }

  void runMutation(Map<String, dynamic> variables) => observableQuery
    ..setVariables(variables)
    ..onData(callbacks) // add callbacks to observable
    ..sendLoading()
    ..fetchResults();

  @override
  void dispose() {
    observableQuery?.close(force: false);
    super.dispose();
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
