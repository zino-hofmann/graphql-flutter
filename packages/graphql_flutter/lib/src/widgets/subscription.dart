import 'dart:async';
import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/widgets.dart';
import 'package:graphql/client.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:graphql_flutter/src/widgets/graphql_provider.dart';

typedef OnSubscriptionResult = void Function(
  QueryResult subscriptionResult,
  GraphQLClient client,
);

typedef SubscriptionBuilder = Widget Function(QueryResult result);

class Subscription<T> extends StatefulWidget {
  const Subscription({
    @required this.options,
    @required this.builder,
    this.onSubscriptionResult,
    Key key,
  }) : super(key: key);

  final SubscriptionOptions options;
  final SubscriptionBuilder builder;
  final OnSubscriptionResult onSubscriptionResult;

  @override
  _SubscriptionState<T> createState() => _SubscriptionState<T>();
}

class _SubscriptionState<T> extends State<Subscription<T>> {
  Stream<QueryResult> stream;
  GraphQLClient client;

  ConnectivityResult _currentConnectivityResult;
  StreamSubscription<ConnectivityResult> _networkSubscription;

  void _initSubscription() {
    final GraphQLClient client = GraphQLProvider.of(context).value;
    assert(client != null);

    stream = client.subscribe(widget.options);

    if (widget.onSubscriptionResult != null) {
      stream = stream.map((result) {
        widget.onSubscriptionResult(result, client);
        return result;
      });
    }
  }

  @override
  void initState() {
    _networkSubscription =
        Connectivity().onConnectivityChanged.listen(_onNetworkChange);

    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final GraphQLClient newClient = GraphQLProvider.of(context).value;
    assert(newClient != null);
    if (client != newClient) {
      client = newClient;
      _initSubscription();
    }
  }

  @override
  void didUpdateWidget(Subscription<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.options.equal(oldWidget.options)) {
      _initSubscription();
    }
  }

  @override
  void dispose() {
    _networkSubscription?.cancel();
    super.dispose();
  }

  Future _onNetworkChange(ConnectivityResult result) async {
    //if from offline to online
    if (_currentConnectivityResult == ConnectivityResult.none &&
        (result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi)) {
      _currentConnectivityResult = result;

      // android connectivitystate cannot be trusted
      // validate with nslookup
      if (Platform.isAndroid) {
        try {
          final nsLookupResult = await InternetAddress.lookup('google.com');
          if (nsLookupResult.isNotEmpty &&
              nsLookupResult[0].rawAddress.isNotEmpty) {
            _initSubscription();
          }
          // on exception -> no real connection, set current state to none
        } on SocketException catch (_) {
          _currentConnectivityResult = ConnectivityResult.none;
        }
      } else {
        _initSubscription();
      }
    } else {
      _currentConnectivityResult = result;
    }
  }

  @override
  Widget build(final BuildContext context) {
    return StreamBuilder<QueryResult>(
      initialData: widget.options?.optimisticResult != null
          ? QueryResult.optimistic(data: widget.options?.optimisticResult)
          : QueryResult.loading(),
      stream: stream,
      builder: (
        BuildContext buildContext,
        AsyncSnapshot<QueryResult> snapshot,
      ) {
        return widget?.builder(snapshot.data);
      },
    );
  }
}
