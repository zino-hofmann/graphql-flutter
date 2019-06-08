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

typedef OnMutationCompleted = void Function(dynamic data);
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

  OnData get onCompleted {
    if (widget.onCompleted != null) {
      return (QueryResult result) {
        if (!result.loading && !result.optimistic) {
          widget.onCompleted(result.data);
        }
      };
    }
    return null;
  }

  /// The optimistic cache layer id `update` will write to
  /// is a "child patch" of the default optimistic patch
  /// created by the query manager
  String get _patchId => '${observableQuery.queryId}.update';

  /// apply the user's patch
  void _optimisticUpdate(QueryResult result) {
    final Cache cache = client.cache;
    final String patchId = _patchId;
    // this is also done in query_manager, but better safe than sorry
    assert(cache is OptimisticCache,
        "can't optimisticly update non-optimistic cache");
    (cache as OptimisticCache).addOptimisiticPatch(patchId, (Cache cache) {
      widget.update(cache, result);
      return cache;
    });
  }

  // optimistic patches will be cleaned up by the query_manager
  // cleanup is handled by heirarchical optimism -
  // as in, because our patch id is prefixed with '${observableQuery.queryId}.',
  // it will be discarded along with the observableQuery.queryId patch
  // TODO this results in an implicit coupling with the patch id system
  OnData get update {
    if (widget.update != null) {
      // dereference all variables that might be needed if the widget is disposed
      final Cache cache = client.cache;
      final OnMutationUpdate widgetUpdate = widget.update;
      final OnData optimisticUpdate = _optimisticUpdate;

      // wrap update logic to handle optimism
      void updateOnData(QueryResult result) {
        if (result.optimistic) {
          return optimisticUpdate(result);
        } else {
          widgetUpdate(cache, result);
        }
      }

      return updateOnData;
    }
    return null;
  }

  // callbacks will be called against each result in the stream,
  // which should then rebroadcast queries with the appropriate optimism
  Iterable<OnData> get callbacks =>
      <OnData>[onCompleted, update].where(notNull);

  /// Run the mutation with the given `variables` and `optimisticResult`,
  /// returning a [MultiSourceResult] for handling both the eager and network results
  MultiSourceResult runMutation(
    Map<String, dynamic> variables, {
    Object optimisticResult,
  }) =>
      (observableQuery
            ..variables = variables
            ..options.optimisticResult = optimisticResult
            ..onData(callbacks) // add callbacks to observable
          )
          .fetchResults();

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
