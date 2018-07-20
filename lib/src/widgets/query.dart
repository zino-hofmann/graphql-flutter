import 'dart:async';
import 'package:flutter/widgets.dart';

import 'package:graphql_flutter/src/client.dart';
import 'package:graphql_flutter/src/widgets/graphql_provider.dart';

typedef Widget QueryBuilder({
  @required bool loading,
  Map<String, dynamic> data,
  String error,
});

class Query extends StatefulWidget {
  Query(
    this.query, {
    final Key key,
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

class QueryState extends State<Query> {
  bool loading = true;
  Map<String, dynamic> data = {};
  String error = '';

  bool initialFetch = true;
  Duration pollInterval;
  Timer pollTimer;
  Map currentVariables = new Map();

  @override
  void initState() {
    super.initState();

    if (widget.pollInterval is int) {
      pollInterval = new Duration(seconds: widget.pollInterval);
    }

    getQueryResult();
  }

  @override
  void dispose() {
    _deleteTimer();

    super.dispose();
  }

  void _deleteTimer() {
    if (pollTimer is Timer) {
      pollTimer.cancel();
      pollTimer = null;
    }
  }

  void getQueryResult() async {
    /// Gets the client from the closest wrapping [GraphqlProvider].
    Client client = GraphqlProvider.of(context).value;
    assert(client != null);

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
    } catch (e) {
      if (data == {}) {
        setState(() {
          error = e.toString();
          loading = false;
        });
      }

      // TODO: handle error
      print(e.toString());
    }

    if (pollInterval is Duration && !(pollTimer is Timer)) {
      pollTimer = new Timer.periodic(
        pollInterval,
        (Timer t) => getQueryResult(),
      );
    }
  }

  bool _areDifferentMaps(Map a, Map b) {
    if (a.length != b.length) {
      return true;
    }

    bool areDifferent = false;

    a.forEach((key, value) {
      if (b[key] != a[key] || (!b.containsKey(key))) {
        areDifferent = true;
      }
    });

    return areDifferent;
  }

  Widget build(BuildContext context) {
    if (initialFetch) {
      initialFetch = false;
      currentVariables = widget.variables;

      getQueryResult();
    }

    if (_areDifferentMaps(currentVariables, widget.variables)) {
      currentVariables = widget.variables;

      loading = true;
      _deleteTimer();

      getQueryResult();
    }

    return widget.builder(
      loading: loading,
      error: error,
      data: data,
    );
  }
}
