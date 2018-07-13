import 'dart:async';
import 'package:flutter/widgets.dart';

import '../client.dart';

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

class QueryState extends State<Query> {
  bool loading = true;
  Map<String, dynamic> data = {};
  String error = '';
  Duration pollInterval;
  Timer pollTimer;
  bool initialFetch = false;
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
        pollTimer = new Timer(pollInterval, () => getQueryResult());
      }
    } catch (e) {
      if (data == {}) {
        setState(() {
          error = e.toString();
          loading = false;
        });
      }

      if (pollInterval is Duration && !(pollTimer is Timer)) {
        pollTimer = new Timer(pollInterval, () => getQueryResult());
      }

      // TODO: handle error
      print(e.toString());
    }
  }

  bool _areDifferentMaps(Map a, Map b) {
    if (a.length != b.length) {
      return true;
    }

    bool areDifferent = false;

    a.forEach((key, value) {
      if (b[key] != a[key]) {
        areDifferent = true;
      }
    });

    return areDifferent;
  }

  Widget build(BuildContext context) {
    if (!initialFetch) {
      initialFetch = true;

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
