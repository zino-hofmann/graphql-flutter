import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:graphql_flutter/src/websocket/messages.dart';
import 'package:uuid/uuid.dart';

SocketClient socketClient;

class SocketClientConfig {
  /// Whether to reconnect to the server after detecting connection loss.
  final bool autoReconnect;

  /// The duration after which the connection is considered unstable, because no keep alive message
  /// was received from the server in the given time-frame. The connection to the server will be closed.
  /// If [autoReconnect] is set to true, we try to reconnect to the server.
  ///
  /// If null, the keep alive messages will be ignored.
  final Duration inactivityTimeout;

  /// The duration after a connection loss that needs to pass before trying to reconnect to the server.
  /// This only takes effect when [autoReconnect] is set to true.
  ///
  /// If null, the reconnection will occur immediately, although not recommended.
  final Duration delayBetweenReconnectionAttempts;

  const SocketClientConfig(
      {this.autoReconnect = true,
      this.inactivityTimeout = const Duration(seconds: 30),
      this.delayBetweenReconnectionAttempts = const Duration(seconds: 5)});
}

enum SocketConnectionState { NOT_CONNECTED, CONNECTING, CONNECTED }

/// Wraps a standard web socket instance to marshal and un-marshal the server /
/// client payloads into dart object representation.
///
/// This class also deals with reconnection, handles timeout and keep alive messages.
///
/// It is meant to be instantiated once, and you can let this class handle all the heavy-
/// lifting of socket state management. Once you're done with the socket connection, make sure
/// you call the [dispose] method to release all allocated resources.
class SocketClient {
  final Uuid _uuid = Uuid();
  final String url;
  final SocketClientConfig config;
  final Iterable<String> protocols;
  final Map<String, String> initPayload;
  final Map<String, dynamic> headers;
  final CompressionOptions compression;
  final _connectionStateController = StreamController<SocketConnectionState>.broadcast();
  final _messageController = StreamController<GraphQLSocketMessage>.broadcast();

  bool disposed = false;
  WebSocket _socket;

  StreamSubscription<ConnectionKeepAlive> _keepAliveSubscription;
  StreamSubscription<GraphQLSocketMessage> _messageSubscription;
  StreamSubscription<SocketConnectionState> _connectionStateSubscription;

  SocketClient(this.url,
      {this.protocols = const <String>[
        'graphql-ws',
      ],
      this.headers = const <String, String>{
        'content-type': 'application/json',
      },
      this.compression = CompressionOptions.compressionDefault,
      this.config = const SocketClientConfig(),
      this.initPayload}) {
    _connectionStateSubscription = connectionState.listen((SocketConnectionState state) {
      print('WebSocket connection state changed to: $state');
    });

    _connect();
  }

  /// Connects to the server.
  ///
  /// If this instance is disposed, this method does nothing.
  Future<void> _connect({Duration delayUntilConnectionAttempt}) async {
    if (disposed) return;

    if (delayUntilConnectionAttempt != null) {
      print('Scheduling to connect in ${delayUntilConnectionAttempt.inSeconds} seconds...');
      await Future<void>.delayed(delayUntilConnectionAttempt);
    }

    if (_socket != null) print('Reconnecting to socket...');
    _connectionStateController.add(SocketConnectionState.CONNECTING);

    try {
      _socket = await WebSocket.connect(url, protocols: protocols, headers: headers, compression: compression);
      _connectionStateController.add(SocketConnectionState.CONNECTED);
      _write(InitOperation(initPayload));

      final messageStream = _socket.asBroadcastStream().map<GraphQLSocketMessage>(_parseSocketMessage);
      _messageController.addStream(messageStream);

      if (config.inactivityTimeout != null) {
        _keepAliveSubscription = _connectionKeepAlive.timeout(config.inactivityTimeout, onTimeout: (event) {
          event.close();
          _socket.close(WebSocketStatus.goingAway);
        }).listen(null);
      }

      _messageSubscription = messageStream.listen(
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
    _messageSubscription?.cancel();
    _connectionStateController.add(SocketConnectionState.NOT_CONNECTED);

    if (config.autoReconnect && !disposed) {
      _connect(delayUntilConnectionAttempt: config.delayBetweenReconnectionAttempts);
    }
  }

  /// Closes the underlying socket if connected, and stops reconnection attempts.
  /// After calling this method, this [SocketClient] instance must be considered
  /// unusable. Instead, create a new instance of this class.
  ///
  /// Use this method if you'd like to disconnect from the specified server permanently,
  /// and you'd like to connect to another server instead of the current one.
  void dispose() {
    disposed = true;
    _socket?.close();
    _keepAliveSubscription?.cancel();
    _messageSubscription?.cancel();
    _connectionStateSubscription?.cancel();
  }

  static GraphQLSocketMessage _parseSocketMessage(dynamic message) {
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

  void _write(final GraphQLSocketMessage message) {
    _socket.add(
      json.encode(
        message,
        toEncodable: (dynamic m) => m.toJson(),
      ),
    );
  }

  Stream<SocketConnectionState> get connectionState => _connectionStateController.stream.distinct();

  Stream<ConnectionAck> get _connectionAck =>
      _messageController.stream.where((GraphQLSocketMessage message) => message is ConnectionAck).cast<ConnectionAck>();

  Stream<ConnectionError> get _connectionError =>
      _messageController.stream.where((GraphQLSocketMessage message) => message is ConnectionError).cast<ConnectionError>();

  Stream<ConnectionKeepAlive> get _connectionKeepAlive =>
      _messageController.stream.where((GraphQLSocketMessage message) => message is ConnectionKeepAlive).cast<ConnectionKeepAlive>();

  Stream<UnknownData> get _unknownData =>
      _messageController.stream.where((GraphQLSocketMessage message) => message is UnknownData).cast<UnknownData>();

  Stream<SubscriptionData> get _subscriptionData =>
      _messageController.stream.where((GraphQLSocketMessage message) => message is SubscriptionData).cast<SubscriptionData>();

  Stream<SubscriptionError> get _subscriptionError =>
      _messageController.stream.where((GraphQLSocketMessage message) => message is SubscriptionError).cast<SubscriptionError>();

  Stream<SubscriptionComplete> get _subscriptionComplete =>
      _messageController.stream.where((GraphQLSocketMessage message) => message is SubscriptionComplete).cast<SubscriptionComplete>();

  Stream<SubscriptionData> subscribe(final SubscriptionRequest payload) {
    final String id = _uuid.v4();

    final StreamController<SubscriptionData> response = StreamController<SubscriptionData>();

    final Stream<SubscriptionComplete> complete = _subscriptionComplete.where((SubscriptionComplete message) => message.id == id).take(1);

    final Stream<SubscriptionData> data =
        _subscriptionData.where((SubscriptionData message) => message.id == id).takeWhile((_) => !response.isClosed);

    final Stream<SubscriptionError> error =
        _subscriptionError.where((SubscriptionError message) => message.id == id).takeWhile((_) => !response.isClosed);

    complete.listen((_) => response.close());
    data.listen((SubscriptionData message) => response.add(message));
    error.listen((SubscriptionError message) => response.addError(message));

    connectionState
        .where((SocketConnectionState state) => state == SocketConnectionState.CONNECTED)
        .takeWhile((_) => !response.isClosed)
        .listen((_) => _write(StartOperation(id, payload)));

    // response.onListen = () => );
    response.onCancel = () {
      _write(StopOperation(id));
    };

    return response.stream;
  }
}
