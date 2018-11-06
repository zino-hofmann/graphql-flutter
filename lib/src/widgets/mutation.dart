import 'package:flutter/widgets.dart';

import 'package:graphql_flutter/src/graphql_client.dart';
import 'package:graphql_flutter/src/core/observable_query.dart';
import 'package:graphql_flutter/src/core/query_options.dart';
import 'package:graphql_flutter/src/core/query_result.dart';
import 'package:graphql_flutter/src/cache/cache.dart';
import 'package:graphql_flutter/src/utilities/helpers.dart';
import 'package:graphql_flutter/src/cache/optimistic.dart';

import 'package:graphql_flutter/src/widgets/graphql_provider.dart';

typedef RunMutation = void Function(
  Map<String, dynamic> variables, {
  Object optimisticResult,
});

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
    final Cache cache = client.cache;
    final String mutationId = observableQuery.queryId;
    if (widget.update != null) {
      void updateOnData(QueryResult result) {
        widget.update(cache, result);
        if (cache is OptimisticCache) {
          cache.removeOptimisticPatch(mutationId);
        }
      }

      return updateOnData;
    }
    return null;
  }

  Iterable<OnData> get callbacks {
    return <OnData>[widget.onCompleted, update].where(notNull);
  }

  // TODO not sure if we're properly caching results without update callbacks
  /// handles optimistic updates
  void handleOptimism(Object optimisticResult) {
    final Cache cache = client.cache;
    final String mutationId = observableQuery.queryId;
    if (optimisticResult != null &&
        widget.update != null &&
        cache is OptimisticCache) {
      cache.addOptimisiticPatch(mutationId, (Cache cache) {
        widget.update(
          cache,
          QueryResult(
            loading: true,
            optimistic: true,
            data: optimisticResult,
          ),
        );
        return cache;
      });
      observableQuery.queryManager.rebroadcastQueries(
        optimistic: true,
      );
    }
  }

  void runMutation(Map<String, dynamic> variables, {Object optimisticResult}) {
    observableQuery
      ..setVariables(variables)
      ..onData(callbacks) // add callbacks to observable
      ..addResult(QueryResult(loading: true))
      ..fetchResults();

    handleOptimism(optimisticResult);
  }

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
