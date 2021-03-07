import 'package:flutter/widgets.dart';

import 'package:graphql/client.dart';

import 'package:graphql_flutter/src/widgets/graphql_provider.dart';

typedef RunMutation = MultiSourceResult Function(
  Map<String, dynamic> variables, {
  Object? optimisticResult,
});

typedef MutationBuilder = Widget Function(
  RunMutation runMutation,
  QueryResult? result,
);

/// Builds a [Mutation] widget based on the a given set of [MutationOptions]
/// that streams [QueryResult]s into the [QueryBuilder].
class Mutation extends StatefulWidget {
  const Mutation({
    final Key? key,
    required this.options,
    required this.builder,
  }) : super(key: key);

  final MutationOptions options;
  final MutationBuilder builder;

  @override
  MutationState createState() => MutationState();
}

class MutationState extends State<Mutation> {
  GraphQLClient? client;
  ObservableQuery? observableQuery;

  WatchQueryOptions? __cachedOptions;

  WatchQueryOptions get _providedOptions {
    final _options = WatchQueryOptions(
      document: widget.options.document,
      variables: widget.options.variables,
      fetchPolicy: widget.options.fetchPolicy,
      errorPolicy: widget.options.errorPolicy,
      cacheRereadPolicy: widget.options.cacheRereadPolicy,
      fetchResults: false,
      context: widget.options.context,
    );
    __cachedOptions ??= _options;
    return _options;
  }

  /// sets new options, returning true if they didn't equal the old
  bool _setNewOptions() {
    final _cached = __cachedOptions;
    final _new = _providedOptions;
    if (_cached == null || !_new.equal(_cached)) {
      __cachedOptions = _new;
      return true;
    }
    return false;
  }

  // TODO is it possible to extract shared logic into mixin
  void _initQuery() {
    observableQuery?.close();
    observableQuery = client!.watchMutation(_providedOptions.copy());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final GraphQLClient client = GraphQLProvider.of(context).value;
    if (client != this.client) {
      this.client = client;
      _initQuery();
    }
  }

  @override
  void didUpdateWidget(Mutation oldWidget) {
    super.didUpdateWidget(oldWidget);

    // TODO @micimize - investigate why/if this was causing issues
    if (_setNewOptions()) {
      _initQuery();
    }
  }

  /// Run the mutation with the given `variables` and `optimisticResult`,
  /// returning a [MultiSourceResult] for handling both the eager and network results
  MultiSourceResult runMutation(
    Map<String, dynamic> variables, {
    Object? optimisticResult,
  }) {
    final mutationCallbacks = MutationCallbackHandler(
      cache: client!.cache,
      queryId: observableQuery!.queryId,
      options: widget.options,
    );

    return (observableQuery!
          ..variables = variables
          ..options.optimisticResult = optimisticResult
          ..onData(mutationCallbacks.callbacks) // add callbacks to observable
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
    return StreamBuilder<QueryResult?>(
      initialData: observableQuery?.latestResult ?? QueryResult.unexecuted,
      stream: observableQuery?.stream,
      builder: (
        BuildContext buildContext,
        AsyncSnapshot<QueryResult?> snapshot,
      ) {
        return widget.builder(
          runMutation,
          snapshot.data,
        );
      },
    );
  }
}
