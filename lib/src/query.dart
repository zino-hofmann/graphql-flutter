import 'dart:async';
import 'package:flutter/widgets.dart';

import './client.dart';

typedef Widget QueryBuilder({
  bool loading,
  // TODO: use a more exact type
  var data,
  String error,
});

class Query extends StatefulWidget {
  Query(
    this.query, {
    Key key,
    this.variables = const {},
    @required this.builder,
    this.polling = 10,
  }) : super(key: key);

  final String query;
  final Map variables;
  final QueryBuilder builder;
  final int polling;

  @override
  QueryState createState() => new QueryState();
}

class QueryState extends State<Query> with WidgetsBindingObserver {
  bool loading = true;
  Object data = {};
  String error = '';
  Duration pollingInterval;

  @override
  void initState() {
    super.initState();

    pollingInterval = new Duration(seconds: widget.polling);
    getQueryResult();
  }

  void getQueryResult() async {
    try {
      final result = await client.execute(
        query: widget.query,
        variables: widget.variables,
      );

      setState(() {
        loading = false;
        error = '';
        data = result;
      });

      new Timer(pollingInterval, getQueryResult);
    } catch (e) {
      setState(() {
        error = 'GQL ERROR';
        loading = false;
      });

      new Timer(pollingInterval, getQueryResult);

      // TODO: Handle error
      print(e);
    }
  }

  Widget build(BuildContext context) {
    return widget.builder(
      loading: loading,
      error: error,
      data: data,
    );
  }
}
