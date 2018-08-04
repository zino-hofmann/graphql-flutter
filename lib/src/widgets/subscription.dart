import 'dart:async';

import 'package:flutter/widgets.dart';

import '../websocket/messages.dart';
import '../socket_client.dart';

typedef OnSubscriptionCompleted = void Function();

typedef SubscriptionBuilder = Widget Function({
  final bool loading,
  final dynamic payload,
  final dynamic error,
});

class Subscription extends StatefulWidget {
  final String operationName;
  final String query;
  final dynamic variables;
  final SubscriptionBuilder builder;
  final OnSubscriptionCompleted onCompleted;
  final dynamic initial;

  Subscription(
    this.operationName,
    this.query, {
    this.variables = const {},
    final Key key,
    @required this.builder,
    this.initial,
    this.onCompleted,
  }) : super(key: key);

  @override
  _SubscriptionState createState() => _SubscriptionState();
}

class _SubscriptionState extends State<Subscription> {
  bool _loading = true;
  dynamic _data;
  dynamic _error;

  bool _alive = true;

  @override
  void initState() {
    super.initState();

    final Stream<SubscriptionData> stream = socketClient.subscribe(
        SubscriptionRequest(
            widget.operationName, widget.query, widget.variables));

    stream.takeWhile((message) => this._alive).listen(
          _onData,
          onError: _onError,
          onDone: _onDone,
        );

    if (widget.initial != null) {
      setState(() {
        _loading = true;
        _data = widget.initial;
        _error = null;
      });
    }
  }

  @override
  void dispose() {
    _alive = false;
    super.dispose();
  }

  void _onData(final SubscriptionData message) {
    setState(() {
      _loading = false;
      _data = message.data;
      _error = message.errors;
    });
  }

  void _onError(final Object error) {
    setState(() {
      _loading = false;
      _data = null;
      _error = (error is SubscriptionError) ? error.payload : error;
    });
  }

  void _onDone() {
    if (widget.onCompleted != null) {
      widget.onCompleted();
    }
  }

  Widget build(final BuildContext context) {
    return widget.builder(
      loading: _loading,
      error: _error,
      payload: _data,
    );
  }
}
