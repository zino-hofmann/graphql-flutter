import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'package:graphql/src/links/gql_links.dart';
import 'package:meta/meta.dart';

import 'package:graphql/src/core/query_options.dart' show WithType;
import 'package:gql_exec/gql_exec.dart';
import 'package:websocket/websocket.dart' show WebSocket, WebSocketStatus;

import 'package:rxdart/rxdart.dart';
import 'package:uuid_enhanced/uuid.dart';

import './websocket_messages.dart';

typedef GetInitPayload = FutureOr<dynamic> Function();

class SubscriptionListener {
  Function callback;
  bool hasBeenTriggered = false;

  SubscriptionListener(this.callback, this.hasBeenTriggered);
}

class SocketClientConfig {
  const SocketClientConfig({
    this.serializer = const RequestSerializer(),
    this.parser = const ResponseParser(),
    this.autoReconnect = true,
    this.queryAndMutationTimeout = const Duration(seconds: 10),
    this.inactivityTimeout = const Duration(seconds: 30),
    this.delayBetweenReconnectionAttempts = const Duration(seconds: 5),
    this.onConnectOrReconnect,
    dynamic initialPayload,
    @deprecated dynamic initPayload,
  })
  // ignore: deprecated_member_use_from_same_package
  : initialPayload = initialPayload ?? initPayload;

  /// Serializer used to serialize request
  final RequestSerializer serializer;

  /// Response parser
  final ResponseParser parser;

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

  /// The duration after which a query or mutation should time out.
  /// If null, no timeout is applied, although not recommended.
  final Duration queryAndMutationTimeout;

  /// Callback for handling connections and reconnections.
  ///
  /// Useful for registering custom listeners or extracting the socket for other non-graphql features.
  final void Function(WebSocket socket) onConnectOrReconnect;

  /// Payload to be sent with the connection_init request.
  ///
  /// Can be a literal value, a callback, or an async callback. End value must be valid argument for `json.encode`.
  ///
  /// Internal usage is roughly:
  /// ```dart
  /// Future<InitOperation> get initOperation async {
  ///   if (initialPayload is Function) {
  ///     final dynamic payload = await initialPayload();
  ///     return InitOperation(payload);
  ///   } else {
  ///     return InitOperation(initialPayload);
  ///   }
  /// }
  /// ```
  final dynamic initialPayload;

  Future<InitOperation> get initOperation async {
    if (initialPayload is Function) {
      final dynamic payload = await initialPayload();
      return InitOperation(payload);
    } else {
      return InitOperation(initialPayload);
    }
  }
}

enum SocketConnectionState { notConnected, connecting, connected }

/// Wraps a standard web socket instance to marshal and un-marshal the server /
/// client payloads into dart object representation.
///
/// This class also deals with reconnection, handles timeout and keep alive messages.
///
/// It is meant to be instantiated once, and you can let this class handle all the heavy-
/// lifting of socket state management. Once you're done with the socket connection, make sure
/// you call the [dispose] method to release all allocated resources.
class SocketClient {
  SocketClient(
    this.url, {
    this.protocols = const <String>[
      'graphql-ws',
    ],
    this.config = const SocketClientConfig(),
    this.connect = WebSocket.connect,
    @visibleForTesting this.randomBytesForUuid,
  }) {
    _connect();
  }

  Uint8List randomBytesForUuid;
  final String url;
  final Iterable<String> protocols;
  final SocketClientConfig config;

  final BehaviorSubject<SocketConnectionState> _connectionStateController =
      BehaviorSubject<SocketConnectionState>();

  final HashMap<String, SubscriptionListener> _subscriptionInitializers =
      HashMap();

  final Future<WebSocket> Function(String url, {Iterable<String> protocols})
      connect;

  bool _connectionWasLost = false;

  Timer _reconnectTimer;
  @visibleForTesting
  WebSocket socket;

  Stream<GraphQLSocketMessage> _messageStream;

  StreamSubscription<ConnectionKeepAlive> _keepAliveSubscription;
  StreamSubscription<GraphQLSocketMessage> _messageSubscription;

  Map<String, dynamic> Function(Request) get serialize =>
      config.serializer.serializeRequest;
  Response Function(Map<String, dynamic>) get parse =>
      config.parser.parseResponse;

  /// Connects to the server.
  ///
  /// If this instance is disposed, this method does nothing.
  Future<void> _connect() async {
    final InitOperation initOperation = await config.initOperation;

    if (_connectionStateController.isClosed) {
      return;
    }

    _connectionStateController.add(SocketConnectionState.connecting);
    print('Connecting to websocket: $url...');

    try {
      socket = await connect(url, protocols: protocols);
      _connectionStateController.add(SocketConnectionState.connected);
      print('Connected to websocket.');
      _write(initOperation);

      _messageStream =
          socket.stream.map<GraphQLSocketMessage>(_parseSocketMessage);

      if (config.inactivityTimeout != null) {
        _keepAliveSubscription = _messagesOfType<ConnectionKeepAlive>().timeout(
          config.inactivityTimeout,
          onTimeout: (EventSink<ConnectionKeepAlive> event) {
            print(
                "Haven't received keep alive message for ${config.inactivityTimeout.inSeconds} seconds. Disconnecting..");
            event.close();
            socket.close(WebSocketStatus.goingAway);
            _connectionStateController.add(SocketConnectionState.notConnected);
          },
        ).listen(null);
      }

      _messageSubscription = _messageStream.listen(
          (dynamic data) {
            // print('data: $data');
          },
          onDone: () {
            // print('done');
            onConnectionLost();
          },
          cancelOnError: true,
          onError: (dynamic e) {
            print('error: $e');
          });

      if (_connectionWasLost) {
        for (SubscriptionListener s in _subscriptionInitializers.values) {
          s.callback();
        }

        _connectionWasLost = false;
      }

      if (config.onConnectOrReconnect != null) {
        config.onConnectOrReconnect(socket);
      }
    } catch (e) {
      onConnectionLost(e);
    }
  }

  void onConnectionLost([e]) {
    if (e != null) {
      print('There was an error causing connection lost: $e');
    }
    print('Disconnected from websocket.');
    _reconnectTimer?.cancel();
    _keepAliveSubscription?.cancel();
    _messageSubscription?.cancel();

    if (_connectionStateController.isClosed) {
      return;
    }

    _connectionWasLost = true;
    _subscriptionInitializers.values.forEach((s) => s.hasBeenTriggered = false);

    if (_connectionStateController.value !=
        SocketConnectionState.notConnected) {
      _connectionStateController.add(SocketConnectionState.notConnected);
    }

    if (config.autoReconnect && !_connectionStateController.isClosed) {
      if (config.delayBetweenReconnectionAttempts != null) {
        print(
            'Scheduling to connect in ${config.delayBetweenReconnectionAttempts.inSeconds} seconds...');

        _reconnectTimer = Timer(
          config.delayBetweenReconnectionAttempts,
          () {
            _connect();
          },
        );
      } else {
        Timer.run(() => _connect());
      }
    }
  }

  /// Closes the underlying socket if connected, and stops reconnection attempts.
  /// After calling this method, this [SocketClient] instance must be considered
  /// unusable. Instead, create a new instance of this class.
  ///
  /// Use this method if you'd like to disconnect from the specified server permanently,
  /// and you'd like to connect to another server instead of the current one.
  Future<void> dispose() async {
    print('Disposing socket client..');
    _reconnectTimer?.cancel();
    await Future.wait([
      socket?.close(),
      _messageSubscription?.cancel(),
      _connectionStateController?.close(),
      _keepAliveSubscription?.cancel()
    ].where((future) => future != null).toList());
  }

  static GraphQLSocketMessage _parseSocketMessage(dynamic message) {
    final Map<String, dynamic> map =
        json.decode(message as String) as Map<String, dynamic>;
    final String type = (map['type'] ?? 'unknown') as String;
    final dynamic payload = map['payload'] ?? <String, dynamic>{};
    final String id = (map['id'] ?? 'none') as String;

    switch (type) {
      case MessageTypes.connectionAck:
        return ConnectionAck();
      case MessageTypes.connectionError:
        return ConnectionError(payload);
      case MessageTypes.connectionKeepAlive:
        return ConnectionKeepAlive();
      case MessageTypes.data:
        final dynamic data = payload['data'];
        final dynamic errors = payload['errors'];
        return SubscriptionData(id, data, errors);
      case MessageTypes.error:
        return SubscriptionError(id, payload);
      case MessageTypes.complete:
        return SubscriptionComplete(id);
      default:
        return UnknownData(map);
    }
  }

  void _write(final GraphQLSocketMessage message) {
    if (_connectionStateController.value == SocketConnectionState.connected) {
      socket.add(
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
  Stream<Response> subscribe(
    final Request payload,
    final bool waitForConnection,
  ) {
    final String id = Uuid.randomUuid(random: randomBytesForUuid).toString();
    final StreamController<Response> response = StreamController<Response>();
    StreamSubscription<SocketConnectionState> sub;
    final bool addTimeout =
        !payload.isSubscription && config.queryAndMutationTimeout != null;

    final onListen = () {
      final Stream<SocketConnectionState> waitForConnectedStateWithoutTimeout =
          _connectionStateController
              .startWith(
                  waitForConnection ? null : SocketConnectionState.connected)
              .where((SocketConnectionState state) =>
                  state == SocketConnectionState.connected)
              .take(1);

      final Stream<SocketConnectionState> waitForConnectedState = addTimeout
          ? waitForConnectedStateWithoutTimeout.timeout(
              config.queryAndMutationTimeout,
              onTimeout: (EventSink<SocketConnectionState> event) {
                print('Connection timed out.');
                response.addError(TimeoutException('Connection timed out.'));
                event.close();
                response.close();
              },
            )
          : waitForConnectedStateWithoutTimeout;

      sub = waitForConnectedState.listen((_) {
        final Stream<GraphQLSocketMessage> dataErrorComplete =
            _messageStream.where(
          (GraphQLSocketMessage message) {
            if (message is SubscriptionData) {
              return message.id == id;
            }

            if (message is SubscriptionError) {
              return message.id == id;
            }

            if (message is SubscriptionComplete) {
              return message.id == id;
            }

            return false;
          },
        ).takeWhile((_) => !response.isClosed);

        final Stream<GraphQLSocketMessage> subscriptionComplete = addTimeout
            ? dataErrorComplete
                .where((message) => message is SubscriptionComplete)
                .take(1)
                .timeout(
                config.queryAndMutationTimeout,
                onTimeout: (EventSink<GraphQLSocketMessage> event) {
                  print('Request timed out.');
                  response.addError(TimeoutException('Request timed out.'));
                  event.close();
                  response.close();
                },
              )
            : dataErrorComplete
                .where((message) => message is SubscriptionComplete)
                .take(1);

        subscriptionComplete.listen((_) => response.close());

        dataErrorComplete
            .where((message) => message is SubscriptionData)
            .cast<SubscriptionData>()
            .listen((message) => response.add(
                  parse(message.toJson()),
                ));

        dataErrorComplete
            .where((message) => message is SubscriptionError)
            .cast<SubscriptionError>()
            .listen((message) => response.addError(message));

        if (!_subscriptionInitializers[id].hasBeenTriggered) {
          _write(
            StartOperation(
              id,
              serialize(payload),
            ),
          );
          _subscriptionInitializers[id].hasBeenTriggered = true;
        }
      });
    };

    response.onListen = onListen;

    response.onCancel = () {
      _subscriptionInitializers.remove(id);

      sub?.cancel();
      if (_connectionStateController.value == SocketConnectionState.connected &&
          socket != null) {
        _write(StopOperation(id));
      }
    };

    _subscriptionInitializers[id] = SubscriptionListener(onListen, false);

    return response.stream;
  }

  /// These streams will emit done events when the current socket is done.
  /// A stream that emits the last value of the connection state upon subscription.
  Stream<SocketConnectionState> get connectionState =>
      _connectionStateController.stream;

  /// Filter `_messageStream` for messages of the given type of [GraphQLSocketMessage]
  ///
  /// Example usages:
  /// `_messagesOfType<ConnectionAck>()` for init acknowledgments
  /// `_messagesOfType<ConnectionError>()` for errors
  /// `_messagesOfType<UnknownData>()` for unknown data messages
  Stream<M> _messagesOfType<M extends GraphQLSocketMessage>() => _messageStream
      .where((GraphQLSocketMessage message) => message is M)
      .cast<M>();
}
