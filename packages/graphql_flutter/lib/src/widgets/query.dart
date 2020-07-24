import 'package:flutter/widgets.dart';

import 'package:graphql/client.dart';
import 'package:graphql/internal.dart';

import 'package:graphql_flutter/src/widgets/graphql_provider.dart';

// method to call from widget to fetchmore queries
typedef FetchMore = dynamic Function(FetchMoreOptions options);

typedef Refetch = Future<QueryResult> Function();

typedef QueryBuilder = Widget Function(
  QueryResult result, {
  Refetch refetch,
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
  GraphQLClient _client;
  WatchQueryOptions get _options {
    final QueryOptions options = widget.options;

    return WatchQueryOptions(
      // ignore: deprecated_member_use
      document: options.document,
      documentNode: options.documentNode,
      variables: options.variables,
      fetchPolicy: options.fetchPolicy,
      errorPolicy: options.errorPolicy,
      pollInterval: options.pollInterval,
      fetchResults: true,
      context: options.context,
      optimisticResult: options.optimisticResult,
    );
  }

  void _initQuery() {
    observableQuery?.close();
    observableQuery = _client.watchQuery(_options);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final GraphQLClient client = GraphQLProvider.of(context).value;
    assert(client != null);
    if (client != _client) {
      _client = client;
      _initQuery();
    }
  }

  @override
  void didUpdateWidget(Query oldWidget) {
    super.didUpdateWidget(oldWidget);

    final GraphQLClient client = GraphQLProvider.of(context).value;

    final optionsWithOverrides = _options;
    optionsWithOverrides.policies = client.defaultPolicies.watchQuery
      .withOverrides(optionsWithOverrides.policies);

    if (!observableQuery.options.areEqualTo(optionsWithOverrides)) {
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
      key: Key(observableQuery?.options?.toKey()),
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
