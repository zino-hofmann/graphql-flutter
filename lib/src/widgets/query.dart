import 'package:flutter/widgets.dart';

import 'package:graphql_flutter/src/graphql_client.dart';
import 'package:graphql_flutter/src/core/observable_query.dart';
import 'package:graphql_flutter/src/core/query_options.dart';
import 'package:graphql_flutter/src/core/query_result.dart';

import 'package:graphql_flutter/src/widgets/graphql_provider.dart';

typedef QueryBuilder = Widget Function(QueryResult result);

class Query extends StatefulWidget {
  final QueryOptions options;
  final QueryBuilder builder;

  Query({
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
  initState() {
    super.initState();
    observableQuery = client.query(widget.options);
  }

  @override
  void dispose() {
    observableQuery.close();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    /// Gets the client from the closest wrapping [GraphQLProvider].
    client = GraphQLProvider.of(context).value;

    super.didChangeDependencies();
  }

  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: observableQuery.stream,
      builder: (
        BuildContext buildContext,
        AsyncSnapshot<QueryResult> snapshot,
      ) {
        return widget.builder(snapshot.data);
      },
    );
  }
}
