import 'package:flutter/widgets.dart';

import 'package:graphql/client.dart';
import 'package:graphql/internal.dart';

import 'package:graphql_flutter/src/widgets/graphql_provider.dart';

typedef RunMutation = void Function(
  Map<String, dynamic> variables, {
  Object optimisticResult,
});

typedef MutationBuilder = Widget Function(
  RunMutation runMutation,
  QueryResult result,
);

/// Builds a [Mutation] widget based on the a given set of [MutationOptions]
/// that streams [QueryResult]s into the [QueryBuilder].
class Mutation extends StatefulWidget {
  const Mutation({
    final Key key,
    @required this.options,
    @required this.builder,
  }) : super(key: key);

  final MutationOptions options;
  final MutationBuilder builder;

  @override
  MutationState createState() => MutationState();
}

class MutationState extends State<Mutation> {
  GraphQLClient client;
  ObservableQuery observableQuery;

  WatchQueryOptions get _options => WatchQueryOptions(
        // ignore: deprecated_member_use
        document: widget.options.document,
        documentNode: widget.options.documentNode,
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

  /// Run the mutation with the given `variables` and `optimisticResult`,
  /// returning a [MultiSourceResult] for handling both the eager and network results
  MultiSourceResult runMutation(
    Map<String, dynamic> variables, {
    Object optimisticResult,
  }) {
    final mutationCallbacks = MutationCallbacks(
      cache: client.cache,
      queryId: observableQuery.queryId,
      options: widget.options,
    );

    return (observableQuery
          ..variables = variables
          ..options.optimisticResult = optimisticResult
          ..onData(mutationCallbacks
              .callbacks) // add callbacks to observable // interesting
        )
        .fetchResults();
  }

  @override
  void dispose() {
    observableQuery?.close(force: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QueryResult>(
      // we give the stream builder a key so that
      // toggling mutations at the same place in the tree,
      // such as is done in the example, won't result in bugs
      key: Key(observableQuery?.options?.toKey()),
      initialData: observableQuery?.latestResult ?? QueryResult(),
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
