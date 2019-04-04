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

  void _optimisticUpdate(QueryResult result) {
    final Cache cache = client.cache;
    final String mutationId = observableQuery.queryId;
    if (cache is OptimisticCache) {
      cache.addOptimisiticPatch(mutationId, (Cache cache) {
        widget.update(cache, result);
        return cache;
      });
    } else {
      // TODO better error
      assert(cache is OptimisticCache,
          "can't optimisticly update non-optimistic cache");
    }
  }

  // we have to be careful to collect cleanup information
  // (`mutationId`) __before__ registering callbacks, so that
  // the mutation side effects get properly decoupled
  // from the UI layer.
  // TODO this callbacks approach can be improved upon
  OnData get _cleanupIfOptimistic {
    final Cache cache = client.cache;
    final String mutationId = observableQuery.queryId;
    return (QueryResult result) {
      if (cache is OptimisticCache && !result.loading && !result.optimistic) {
        cache.removeOptimisticPatch(mutationId);
      }
    };
  }

  OnData get update {
    if (widget.update != null) {
      final OnData cleanup = _cleanupIfOptimistic;
      void updateOnData(QueryResult result) {
        if (result.optimistic) {
          return _optimisticUpdate(result);
        } else {
          widget.update(client.cache, result);
          cleanup(result);
        }
      }

      return updateOnData;
    }
    return null;
  }

  // callbacks will be called against each result in the stream,
  // which should then rebroadcast queries with the appropriate optimism
  Iterable<OnData> get callbacks {
    return <OnData>[onCompleted, update].where(notNull);
  }

  // TODO not properly caching results without update callbacks
  // TODO should handle mutations with normalizable optimistic results
  // without update
  /// handles optimistic updates
  void handleOptimism(Object optimisticResult) {
    if (client.cache is OptimisticCache && optimisticResult != null) {
      observableQuery.addResult(QueryResult(
        loading: false,
        optimistic: true,
        data: optimisticResult,
      ));
    }
  }

  void runMutation(Map<String, dynamic> variables, {Object optimisticResult}) {
    observableQuery
      ..variables = variables
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
      // we give the stream builder a key so that
      // toggling mutations at the same place in the tree,
      // such as is done in the example, won't result in bugs
      key: Key(observableQuery?.options?.toKey()),
      initialData: QueryResult(
        loading: false,
        optimistic: false,
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
