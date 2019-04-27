import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:graphql_flutter/src/graphql_client.dart';
import 'package:graphql_flutter/src/link/fetch_result.dart';
import 'package:graphql_flutter/src/link/operation.dart';
import 'package:graphql_flutter/src/utilities/helpers.dart';
import 'package:graphql_flutter/src/widgets/graphql_provider.dart';
import 'package:graphql_flutter/src/websocket/messages.dart';

typedef OnSubscriptionCompleted = void Function();

typedef SubscriptionBuilder<T> = Widget Function({
  bool loading,
  T payload,
  dynamic error,
});

class Subscription<T> extends StatefulWidget {
  const Subscription(
    this.operationName,
    this.query, {
    this.variables = const <String, dynamic>{},
    final Key key,
    @required this.builder,
    this.initial,
    this.onCompleted,
  }) : super(key: key);

  final String operationName;
  final String query;
  final Map<String, dynamic> variables;
  final SubscriptionBuilder<T> builder;
  final OnSubscriptionCompleted onCompleted;
  final T initial;

  @override
  _SubscriptionState<T> createState() => _SubscriptionState<T>();
}

class _SubscriptionState<T> extends State<Subscription<T>> {
  bool _loading = true;
  T _data;
  dynamic _error;
  StreamSubscription<FetchResult> _subscription;

  void _initSubscription() {
    final GraphQLClient client = GraphQLProvider.of(context).value;
    assert(client != null);
    final Operation operation = Operation(
      document: widget.query,
      variables: widget.variables,
      operationName: widget.operationName,
    );

    final Stream<FetchResult> stream = client.subscribe(operation);

    if (_subscription == null) {
      // Set the initial value for the first time.
      if (widget.initial != null) {
        setState(() {
          _loading = true;
          _data = widget.initial;
          _error = null;
        });
      }
    }

    _subscription?.cancel();
    _subscription = stream.listen(
      _onData,
      onError: _onError,
      onDone: _onDone,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initSubscription();
  }

  @override
  void didUpdateWidget(Subscription<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.query != oldWidget.query ||
        widget.operationName != oldWidget.operationName ||
        areDifferentVariables(widget.variables, oldWidget.variables)) {
      _initSubscription();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onData(final FetchResult message) {
    setState(() {
      _loading = false;
      _data = message.data as T;
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

  @override
  Widget build(final BuildContext context) {
    return widget.builder(
      loading: _loading,
      error: _error,
      payload: _data,
    );
  }
}
