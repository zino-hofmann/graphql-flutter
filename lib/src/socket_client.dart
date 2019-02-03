import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:graphql_flutter/src/websocket/messages.dart';
import 'package:rxdart/subjects.dart';
import 'package:uuid/uuid.dart';

SocketClient socketClient;

class SocketClientConfig {
  /// Whether to reconnect to the server after detecting connection loss.
  final bool autoReconnect;

  /// The duration after which the connection is considered unstable, because no keep alive message
  /// was received from the server in the given time-frame. The connection to the server will be closed.
  /// If [autoReconnect] is set to true, we try to reconnect to the server after the specified [delayBetweenReconnectionAttempts].
  ///
  /// If null, the keep alive messages will be ignored.
  final Duration inactivityTimeout;

  /// The duration that needs to pass before trying to reconnect to the server after a connection loss.
  /// This only takes effect when [autoReconnect] is set to true.
  ///
  /// If null, the reconnection will occur immediately, although not recommended.
  final Duration delayBetweenReconnectionAttempts;

  // The duration after which a query or mutation should time out.
  // If null, no timeout is applied, although not recommended.
  final Duration queryAndMutationTimeout;

  const SocketClientConfig(
      {this.autoReconnect = true,
      this.queryAndMutationTimeout = const Duration(seconds: 10),
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
  final _connectionStateController = BehaviorSubject<SocketConnectionState>();

  WebSocket _socket;
  Stream<GraphQLSocketMessage> _messageStream;

  StreamSubscription<ConnectionKeepAlive> _keepAliveSubscription;
  StreamSubscription<GraphQLSocketMessage> _messageSubscription;

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
    _connect();
  }

  /// Connects to the server.
  ///
  /// If this instance is disposed, this method does nothing.
  Future<void> _connect({Duration delayUntilConnectionAttempt}) async {
    if (_connectionStateController.isClosed) return;

    if (delayUntilConnectionAttempt != null) {
      print('Scheduling to connect in ${delayUntilConnectionAttempt.inSeconds} seconds...');
      await Future<void>.delayed(delayUntilConnectionAttempt);
    }

    if (_socket != null) print('Reconnecting to socket...');
    _connectionStateController.value = SocketConnectionState.CONNECTING;
    print('Connecting to websocket: $url...');

    try {
      _socket = await WebSocket.connect(url, protocols: protocols, headers: headers, compression: compression);
      _connectionStateController.value = SocketConnectionState.CONNECTED;
      print('Connected to websocket.');
      _write(InitOperation(initPayload));

      _messageStream = _socket.asBroadcastStream().map<GraphQLSocketMessage>(_parseSocketMessage);

      if (config.inactivityTimeout != null) {
        _keepAliveSubscription = _connectionKeepAlive.timeout(config.inactivityTimeout, onTimeout: (event) {
          print("Haven't received keep alive message for ${config.inactivityTimeout.inSeconds} seconds. Disconnecting..");
          event.close();
          _socket.close(WebSocketStatus.goingAway);
          _connectionStateController.value = SocketConnectionState.NOT_CONNECTED;
        }).listen(null);
      }

      _messageSubscription = _messageStream.listen(
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
    print('Disconnected from websocket.');
    _keepAliveSubscription?.cancel();
    _messageSubscription?.cancel();
    if (_connectionStateController.value != SocketConnectionState.NOT_CONNECTED)
      _connectionStateController.value = SocketConnectionState.NOT_CONNECTED;

    if (config.autoReconnect && !_connectionStateController.isClosed) {
      _connect(delayUntilConnectionAttempt: config.delayBetweenReconnectionAttempts);
    }
  }

  /// Closes the underlying socket if connected, and stops reconnection attempts.
  /// After calling this method, this [SocketClient] instance must be considered
  /// unusable. Instead, create a new instance of this class.
  ///
  /// Use this method if you'd like to disconnect from the specified server permanently,
  /// and you'd like to connect to another server instead of the current one.
  Future<void> dispose() async {
    await _socket?.close();
    await _keepAliveSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _connectionStateController?.close();
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
    if (_connectionStateController.value == SocketConnectionState.CONNECTED) {
      _socket.add(
        json.encode(
          message,
          toEncodable: (dynamic m) => m.toJson(),
        ),
      );
    }
  }

  /// Sends a query, mutation or subscription request to the server, and returns a stream of the response.
  ///
  /// If the request is a query or mutation, a timeout will be applied to the request as specified by
  /// [SocketClientConfig]'s [queryAndMutationTimeout] field.
  ///
  /// If the request is a subscription, obviously no timeout is applied.
  ///
  /// In case of socket disconnection, the returned stream will be closed.
  Stream<SubscriptionData> subscribe(final SubscriptionRequest payload, final bool isSubscription) {
    final String id = _uuid.v4();
    final StreamController<SubscriptionData> response = StreamController<SubscriptionData>();

    response.onListen = () {
      if (_connectionStateController.value == SocketConnectionState.CONNECTED && _socket != null) {
        final dataErrorComplete = _messageStream.where((GraphQLSocketMessage message) {
          if (message is SubscriptionData) return message.id == id;
          if (message is SubscriptionError) return message.id == id;
          if (message is SubscriptionComplete) return message.id == id;
          return false;
        }).takeWhile((_) => !response.isClosed);

        final addTimeout = !isSubscription && config.queryAndMutationTimeout != null;
        final subscriptionComplete = addTimeout
            ? dataErrorComplete
                .where((GraphQLSocketMessage message) => message is SubscriptionComplete)
                .take(1)
                .timeout(config.queryAndMutationTimeout, onTimeout: (e) {
                print('Request timed out.');
                response.addError(TimeoutException('Request timed out.'));
                e.close();
                response.close();
              })
            : dataErrorComplete.where((GraphQLSocketMessage message) => message is SubscriptionComplete).take(1);

        subscriptionComplete.listen((_) => response.close());

        dataErrorComplete
            .where((GraphQLSocketMessage message) => message is SubscriptionData)
            .cast<SubscriptionData>()
            .listen((SubscriptionData message) => response.add(message));

        dataErrorComplete
            .where((GraphQLSocketMessage message) => message is SubscriptionError)
            .listen((GraphQLSocketMessage message) => response.addError(message));

        _write(StartOperation(id, payload));
      } else {
        response.addError(Exception('Not connected to the server.'));
      }
    };
    response.onCancel = () {
      if (_connectionStateController.value == SocketConnectionState.CONNECTED && _socket != null) _write(StopOperation(id));
    };

    return response.stream;
  }

  /// These streams will emit done events when the current socket is done.

  /// A stream that emits the last value of the connection state upon subscription.
  Stream<SocketConnectionState> get connectionState => _connectionStateController.stream;

  Stream<ConnectionAck> get _connectionAck => _messageStream.where((GraphQLSocketMessage message) => message is ConnectionAck).cast<ConnectionAck>();

  Stream<ConnectionError> get _connectionError =>
      _messageStream.where((GraphQLSocketMessage message) => message is ConnectionError).cast<ConnectionError>();

  Stream<ConnectionKeepAlive> get _connectionKeepAlive =>
      _messageStream.where((GraphQLSocketMessage message) => message is ConnectionKeepAlive).cast<ConnectionKeepAlive>();

  Stream<UnknownData> get _unknownData => _messageStream.where((GraphQLSocketMessage message) => message is UnknownData).cast<UnknownData>();
}
