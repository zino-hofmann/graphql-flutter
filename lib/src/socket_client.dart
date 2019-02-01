import 'dart:async';

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:uuid/uuid.dart';

SocketClient socketClient;

class SocketClientConfig {
  /// The duration after which a query or mutation should timeout.
  final Duration queryOrMutationTimeout;

  const SocketClientConfig({this.queryOrMutationTimeout = const Duration(seconds: 30)});
}

class SocketClient {
  final Uuid _uuid = Uuid();
  final GraphQLSocket _socket;
  final SocketClientConfig config;

  SocketClient(this._socket, {this.config = const SocketClientConfig(), Map<String, String> initPayload}) {
    _socket.connectionAck.listen(print);
    _socket.connectionError.listen(print);
    _socket.unknownData.listen(print);

    _socket.connectionState.listen((GraphQLSocketConnectionState state) {
      print('WebSocket connection state changed to: $state');
      if (state == GraphQLSocketConnectionState.CONNECTED) _socket.write(InitOperation(initPayload));
    });
  }

  Stream<SubscriptionData> subscribe(final SubscriptionRequest payload) {
    final String id = _uuid.v4();

    final StreamController<SubscriptionData> response = StreamController<SubscriptionData>();

    final Stream<SubscriptionComplete> complete = _socket.subscriptionComplete.where((SubscriptionComplete message) => message.id == id).take(1);

    final Stream<SubscriptionData> data =
        _socket.subscriptionData.where((SubscriptionData message) => message.id == id).takeWhile((_) => !response.isClosed);

    final Stream<SubscriptionError> error =
        _socket.subscriptionError.where((SubscriptionError message) => message.id == id).takeWhile((_) => !response.isClosed);

    complete.listen((_) => response.close());
    data.listen((SubscriptionData message) => response.add(message));
    error.listen((SubscriptionError message) => response.addError(message));

    _socket.connectionState
        .where((GraphQLSocketConnectionState state) => state == GraphQLSocketConnectionState.CONNECTED)
        .takeWhile((_) => !response.isClosed)
        .listen((_) => _socket.write(StartOperation(id, payload)));

    // response.onListen = () => );
    response.onCancel = () {
      _socket.write(StopOperation(id));
    };

    return response.stream;
  }
}
