import 'package:flutter/widgets.dart';

import 'package:graphql_flutter/src/graphql_client.dart';
import 'package:graphql_flutter/src/core/observable_query.dart';
import 'package:graphql_flutter/src/core/query_options.dart';
import 'package:graphql_flutter/src/core/query_result.dart';

import 'package:graphql_flutter/src/widgets/graphql_provider.dart';

typedef QueryBuilder = Widget Function(QueryResult result);

/// Builds a [Query] widget based on the a given set of [QueryOptions]
/// that streams [QueryResult]s into the [QueryBuilder].
class Query extends StatefulWidget {
  final QueryOptions options;
  final QueryBuilder builder;

  const Query({
    final Key key,
    @required this.options,
    @required this.builder,
  }) : super(key: key);

  @override
  QueryState createState() => QueryState();
}

class QueryState extends State<Query> {
  GraphQLClient client;
  ObservableQuery observableQuery;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    observableQuery?.close();
    super.dispose();
  }

  @override
  void didChangeDependencies() async {
    print('didChangeDependencies');

    /// Gets the client from the closest wrapping [GraphQLProvider].
    client = GraphQLProvider.of(context).value;
    assert(client != null);

    // override the default [QueryOptions] fetchPolicy.
    FetchPolicy fetchPolicy = widget.options.fetchPolicy;

    if (fetchPolicy == FetchPolicy.cacheFirst) {
      fetchPolicy = FetchPolicy.cacheAndNetwork;
    }

    final WatchQueryOptions options = WatchQueryOptions(
      document: widget.options.document,
      variables: widget.options.variables,
      fetchPolicy: fetchPolicy,
      errorPolicy: widget.options.errorPolicy,
      pollInterval: widget.options.pollInterval,
      fetchResults: true,
      context: widget.options.context,
    );

    bool shouldCreateNewObservable = true;

    if (observableQuery != null) {
      if (observableQuery.options.areEqualTo(options)) {
        shouldCreateNewObservable = false;
      }

      await observableQuery.close();
    }

    if (shouldCreateNewObservable) {
      observableQuery = client.watchQuery(options);
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QueryResult>(
      initialData: QueryResult(
        loading: true,
      ),
      stream: observableQuery.stream,
      builder: (
        BuildContext buildContext,
        AsyncSnapshot<QueryResult> snapshot,
      ) {
        return widget?.builder(snapshot.data);
      },
    );
  }
}
