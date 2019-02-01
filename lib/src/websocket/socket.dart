import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:graphql_flutter/src/websocket/messages.dart';

class GraphQLSocketConfig {
  /// Whether to reconnect to the server after detecting connection loss.
  final bool autoReconnect;

  /// The duration after which the connection is considered unstable, because no keep alive message
  /// was received from the server. The connection to the server will be closed. If [autoReconnect] is
  /// set to true, we try to reconnect to the server.
  ///
  /// If null, the keep alive messages will be ignored.
  final Duration inactivityTimeout;

  /// The duration after a connection loss that needs to pass before trying to reconnect to the socket.
  /// This field only takes effect when [autoReconnect] is set to true.
  ///
  /// If null, the reconnection will occur immediately, although not recommended.
  final Duration delayBetweenReconnectionAttempts;

  const GraphQLSocketConfig(
      {this.autoReconnect = true,
      this.inactivityTimeout = const Duration(seconds: 30),
      this.delayBetweenReconnectionAttempts = const Duration(seconds: 5)});
}

enum GraphQLSocketConnectionState { NOT_CONNECTED, CONNECTING, CONNECTED }

/// Wraps a standard web socket instance to marshal and un-marshal the server /
/// client payloads into dart object representation.
///
/// This class also deals with reconnection, handles timeout and keep alive messages.
class GraphQLSocket {
  final String url;
  final Iterable<String> protocols;
  final Map<String, dynamic> headers;
  final CompressionOptions compression;
  final GraphQLSocketConfig config;
  final _connectionStateController = StreamController<GraphQLSocketConnectionState>.broadcast();
  final _messageController = StreamController<GraphQLSocketMessage>.broadcast();
  WebSocket _socket;

  StreamSubscription _keepAliveSubscription;

  GraphQLSocket(this.url,
      {this.protocols = const <String>[
        'graphql-ws',
      ],
      this.headers = const <String, String>{
        'content-type': 'application/json',
      },
      this.compression = CompressionOptions.compressionDefault,
      this.config = const GraphQLSocketConfig()}) {
    _connect();
  }

  Future<void> _connect({Duration delayUntilConnectionAttempt}) async {
    if (delayUntilConnectionAttempt != null) {
      print('Scheduling to connect in ${delayUntilConnectionAttempt.inSeconds} seconds...');
      await Future<void>.delayed(delayUntilConnectionAttempt);
    }

    if (_socket != null) print('Reconnecting to socket...');
    _connectionStateController.add(GraphQLSocketConnectionState.CONNECTING);

    try {
      _socket = await WebSocket.connect(url, protocols: protocols, headers: headers, compression: compression);
      _connectionStateController.add(GraphQLSocketConnectionState.CONNECTED);

      final messageStream = _socket.asBroadcastStream().map<GraphQLSocketMessage>(_parseSocketMessage);
      _messageController.addStream(messageStream);

      if (config.inactivityTimeout != null) {
        _keepAliveSubscription = _connectionKeepAlive.timeout(config.inactivityTimeout, onTimeout: (event) {
          event.close();
          _socket.close(WebSocketStatus.goingAway);
        }).listen(null);
      }

      messageStream.listen(
          (dynamic data) {
            print("data: $data");
          },
          onDone: () {
            print('done');
            onConnectionLost();
          },
          cancelOnError: true,
          onError: (dynamic e) {
            print("error: $e");
          });
    } catch (e) {
      onConnectionLost();
    }
  }

  void onConnectionLost() {
    _keepAliveSubscription?.cancel();
    _connectionStateController.add(GraphQLSocketConnectionState.NOT_CONNECTED);

    if (config.autoReconnect) {
      _connect(delayUntilConnectionAttempt: config.delayBetweenReconnectionAttempts);
    }
  }

  GraphQLSocketMessage _parseSocketMessage(dynamic message) {
    final Map<String, dynamic> map = json.decode(message);
    final String type = map['type'] ?? 'unknown';
    final dynamic payload = map['payload'] ?? <String, dynamic>{};
    final String id = map['id'] ?? 'none';

    switch (type) {
      case MessageTypes.GQL_CONNECTION_ACK:
        return ConnectionAck();
      case MessageTypes.GQL_CONNECTION_ERROR:
        return ConnectionError(payload);
      case MessageTypes.GQL_CONNECTION_KEEP_ALIVE:
        return ConnectionKeepAlive();
      case MessageTypes.GQL_DATA:
        final dynamic data = payload['data'];
        final dynamic errors = payload['errors'];
        return SubscriptionData(id, data, errors);
      case MessageTypes.GQL_ERROR:
        return SubscriptionError(id, payload);
      case MessageTypes.GQL_COMPLETE:
        return SubscriptionComplete(id);
      default:
        return UnknownData(map);
    }
  }

  void write(final GraphQLSocketMessage message) {
    _socket.add(
      json.encode(
        message,
        toEncodable: (dynamic m) => m.toJson(),
      ),
    );
  }

  Stream<GraphQLSocketConnectionState> get connectionState => _connectionStateController.stream.distinct();

  Stream<ConnectionAck> get connectionAck =>
      _messageController.stream.where((GraphQLSocketMessage message) => message is ConnectionAck).cast<ConnectionAck>();

  Stream<ConnectionError> get connectionError =>
      _messageController.stream.where((GraphQLSocketMessage message) => message is ConnectionError).cast<ConnectionError>();

  Stream<ConnectionKeepAlive> get _connectionKeepAlive =>
      _messageController.stream.where((GraphQLSocketMessage message) => message is ConnectionKeepAlive).cast<ConnectionKeepAlive>();

  Stream<UnknownData> get unknownData =>
      _messageController.stream.where((GraphQLSocketMessage message) => message is UnknownData).cast<UnknownData>();

  Stream<SubscriptionData> get subscriptionData =>
      _messageController.stream.where((GraphQLSocketMessage message) => message is SubscriptionData).cast<SubscriptionData>();

  Stream<SubscriptionError> get subscriptionError =>
      _messageController.stream.where((GraphQLSocketMessage message) => message is SubscriptionError).cast<SubscriptionError>();

  Stream<SubscriptionComplete> get subscriptionComplete =>
      _messageController.stream.where((GraphQLSocketMessage message) => message is SubscriptionComplete).cast<SubscriptionComplete>();
}
