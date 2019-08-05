import 'package:flutter/widgets.dart';

import 'package:graphql/client.dart';
import 'package:graphql/internal.dart';

import 'package:graphql_flutter/src/widgets/graphql_provider.dart';

typedef BoolCallback = bool Function();

// method to call from widget to fetchmore queries
typedef dynamic FetchMore(FetchMoreOptions options);

typedef QueryBuilder = Widget Function(
  QueryResult result, {
  BoolCallback refetch,
  FetchMore fetchMore,
});

/// Builds a [Query] widget based on the a given set of [QueryOptions]
/// that streams [QueryResult]s into the [QueryBuilder].
class Query extends StatefulWidget {
  const Query({
    final Key key,
    @required this.options,
    @required this.builder,
  }) : super(key: key);

  final QueryOptions options;
  final QueryBuilder builder;

  @override
  QueryState createState() => QueryState();
}

class QueryState extends State<Query> {
  ObservableQuery observableQuery;

  WatchQueryOptions get _options {
    FetchPolicy fetchPolicy = widget.options.fetchPolicy;

    if (fetchPolicy == FetchPolicy.cacheFirst) {
      fetchPolicy = FetchPolicy.cacheAndNetwork;
    }

    return WatchQueryOptions(
      document: widget.options.document,
      variables: widget.options.variables,
      fetchPolicy: fetchPolicy,
      errorPolicy: widget.options.errorPolicy,
      pollInterval: widget.options.pollInterval,
      fetchResults: true,
      context: widget.options.context,
      optimisticResult: widget.options.optimisticResult,
    );
  }

  void _initQuery() {
    final GraphQLClient client = GraphQLProvider.of(context).value;
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
  void didUpdateWidget(Query oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!observableQuery.options.areEqualTo(_options)) {
      _initQuery();
    }
  }

  @override
  void dispose() {
    observableQuery?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QueryResult>(
      initialData: observableQuery?.latestResult ?? QueryResult(loading: true),
      stream: observableQuery.stream,
      builder: (
        BuildContext buildContext,
        AsyncSnapshot<QueryResult> snapshot,
      ) {
        return widget?.builder(
          snapshot.data,
          refetch: observableQuery.refetch,
          fetchMore: observableQuery.fetchMore,
        );
      },
    );
  }
}
