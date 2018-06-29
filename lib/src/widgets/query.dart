import 'dart:async';
import 'package:flutter/widgets.dart';

import '../client.dart';
import './graphql_provider.dart';

typedef Widget QueryBuilder({
  @required bool loading,
  Map<String, dynamic> data,
  String error,
});

class Query extends StatefulWidget {
  Query(
    this.query, {
    Key key,
    this.variables = const {},
    @required this.builder,
    this.pollInterval,
  }) : super(key: key);

  final String query;
  final Map<String, dynamic> variables;
  final QueryBuilder builder;
  final int pollInterval;

  @override
  QueryState createState() => new QueryState();
}

class QueryState extends State<Query> with WidgetsBindingObserver {
  bool loading = true;
  Map<String, dynamic> data = {};
  String error = '';
  Duration pollInterval;
  Timer pollTimer;
  bool initialFetch = false;

  @override
  void initState() {
    super.initState();

    if (widget.pollInterval is int) {
      pollInterval = new Duration(seconds: widget.pollInterval);
    }
  }

  void getQueryResult(Client client) async {
    try {
      final Map<String, dynamic> result = client.readQuery(
        query: widget.query,
        variables: widget.variables,
      );

      setState(() {
        loading = false;
        error = '';
        data = result;
      });
    } catch (e) {
      print(e.toString());
    }

    try {
      final Map<String, dynamic> result = await client.query(
        query: widget.query,
        variables: widget.variables,
      );

      setState(() {
        loading = false;
        error = '';
        data = result;
      });

      if (pollInterval is Duration && !(pollTimer is Timer)) {
        pollTimer = new Timer(pollInterval, () => getQueryResult(client));
      }
    } catch (e) {
      if (data == {}) {
        setState(() {
          error = e.toString();
          loading = false;
        });
      }

      if (pollInterval is Duration && !(pollTimer is Timer)) {
        pollTimer = new Timer(pollInterval, () => getQueryResult(client));
      }

      // TODO: handle error
      print(e.toString());
    }
  }

  Widget build(BuildContext context) {
    if (!initialFetch) {
      initialFetch = true;

      getQueryResult(GraphqlProvider.of(context).client);
    }

    return widget.builder(
      loading: loading,
      error: error,
      data: data,
    );
  }
}
