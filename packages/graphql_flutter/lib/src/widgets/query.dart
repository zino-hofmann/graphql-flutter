import 'package:flutter/widgets.dart';

import 'package:graphql/client.dart';

import 'package:graphql_flutter/src/widgets/graphql_provider.dart';

// method to call from widget to fetchmore queries
typedef FetchMore<TParsed> = Future<QueryResult<TParsed>> Function(
    FetchMoreOptions options);

typedef Refetch<TParsed> = Future<QueryResult<TParsed>?> Function();

typedef QueryBuilder<TParsed> = Widget Function(
  QueryResult<TParsed> result, {
  Refetch<TParsed>? refetch,
  FetchMore<TParsed>? fetchMore,
});

/// Builds a [Query] widget based on the a given set of [QueryOptions]
/// that streams [QueryResult]s into the [QueryBuilder].
class Query<TParsed> extends StatefulWidget {
  const Query({
    final Key? key,
    required this.options,
    required this.builder,
  }) : super(key: key);

  final QueryOptions<TParsed> options;
  final QueryBuilder<TParsed> builder;

  @override
  QueryState<TParsed> createState() => QueryState();
}

class QueryState<TParsed> extends State<Query<TParsed>> {
  ObservableQuery<TParsed>? observableQuery;
  GraphQLClient? _client;

  WatchQueryOptions<TParsed> get _options =>
      widget.options.asWatchQueryOptions();

  void _initQuery() {
    observableQuery?.close();
    observableQuery = _client!.watchQuery(_options);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final GraphQLClient client = GraphQLProvider.of(context).value;
    if (client != _client) {
      _client = client;
      _initQuery();
    }
  }

  @override
  void didUpdateWidget(Query<TParsed> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final GraphQLClient client = GraphQLProvider.of(context).value;

    final optionsWithOverrides = _options;
    optionsWithOverrides.policies = client.defaultPolicies.watchQuery
        .withOverrides(optionsWithOverrides.policies);

    if (!observableQuery!.options.equal(optionsWithOverrides)) {
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
    return StreamBuilder<QueryResult<TParsed>>(
      initialData: observableQuery?.latestResult ??
          QueryResult.loading(
            parserFn: widget.options.parserFn,
          ),
      stream: observableQuery!.stream,
      builder: (
        BuildContext buildContext,
        AsyncSnapshot<QueryResult<TParsed>> snapshot,
      ) {
        return widget.builder(
          snapshot.data!,
          refetch: observableQuery!.refetch,
          fetchMore: observableQuery!.fetchMore,
        );
      },
    );
  }
}
