import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:gql_exec/gql_exec.dart';
import 'package:graphql/src/core/query_options.dart' show WithType;
import 'package:graphql/src/links/gql_links.dart';
import 'package:graphql/src/utilities/platform.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/uuid_util.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:web_socket_channel/web_socket_channel.dart';

import './websocket_messages.dart';

typedef GetInitPayload = FutureOr<dynamic> Function();

/// A definition for functions that returns a connected [WebSocketChannel]
typedef WebSocketConnect = FutureOr<WebSocketChannel> Function(
  Uri uri,
  Iterable<String>? protocols,
);

// create uuid generator
final _uuid = Uuid(options: {'grng': UuidUtil.cryptoRNG});

class SubscriptionListener {
  Function callback;
  bool hasBeenTriggered = false;

  SubscriptionListener(this.callback, this.hasBeenTriggered);
}

enum SocketConnectionState { notConnected, handshake, connecting, connected }

class SocketClientConfig {
  const SocketClientConfig({
    this.serializer = const RequestSerializer(),
    this.parser = const ResponseParser(),
    this.autoReconnect = true,
    this.queryAndMutationTimeout = const Duration(seconds: 10),
    this.inactivityTimeout = const Duration(seconds: 30),
    this.delayBetweenReconnectionAttempts = const Duration(seconds: 5),
    this.initialPayload,
    this.headers,
    this.connectFn,
  });

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
  final Duration? inactivityTimeout;

  /// The duration that needs to pass before trying to reconnect to the server after a connection loss.
  /// This only takes effect when [autoReconnect] is set to true.
  ///
  /// If null, the reconnection will occur immediately, although not recommended.
  final Duration? delayBetweenReconnectionAttempts;

  /// The duration after which a query or mutation should time out.
  /// If null, no timeout is applied, although not recommended.
  final Duration? queryAndMutationTimeout;

  /// Connect or reconnect to the websocket.
  ///
  /// Useful supplying custom headers to an IO client, registering custom listeners,
  /// and extracting the socket for other non-graphql features.
  ///
  /// Warning: if you want to listen to the stream,
  /// wrap your channel with our [GraphQLWebSocketChannel] using the `.forGraphQL()` helper:
  /// ```dart
  /// connectFn: (url, protocols) {
  ///    var channel = WebSocketChannel.connect(url, protocols: protocols)
  ///    // without this line, our client won't be able to listen to stream events,
  ///    // because you are already listening.
  ///    channel = channel.forGraphQL();
  ///    channel.stream.listen(myListener)
  ///    return channel;
  /// }
  /// ```
  final WebSocketConnect? connectFn;

  /// Custom header to add inside the client
  final Map<String, dynamic>? headers;

  /// Function to define another connection without call directly
  /// the connection function
  FutureOr<WebSocketChannel> connect(
      {required Uri uri,
      Iterable<String>? protocols,
      Map<String, dynamic>? headers}) {
    if (connectFn != null) {
      return connectFn!(uri, protocols);
    }
    return defaultConnectPlatform(
      uri,
      protocols,
      headers: headers ?? this.headers,
    );
  }

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

/// All the protocol supported by the library
@Deprecated(
    "`SocketSubProtocol`is deprecated and will be removed in the version 5.2.0, consider to use `GraphQLProtocol`")
class SocketSubProtocol {
  SocketSubProtocol._();
  /// graphql-ws: The new  (not to be confused with the graphql-ws library).
  /// NB. This protocol is it no longer maintained, please consider
  /// to use `SocketSubProtocol.graphqlTransportWs`.
  static const String graphqlWs = GraphQLProtocol.graphqlWs;
  /// graphql-transport-ws: New ws protocol used by most Apollo Server instances 
  /// with subscriptions enabled use this library.
  /// N.B: not to be confused with the graphql-ws library that implement the 
  /// old ws protocol.
  static const String graphqlTransportWs = GraphQLProtocol.graphqlWs;
}

  /// graphql-ws: The new  (not to be confused with the graphql-ws library).
  /// NB. This protocol is it no longer maintained, please consider
  /// to use `SocketSubProtocol.graphqlTransportWs`.
  static const String graphqlWs = GraphQLProtocol.graphqlWs;

  /// graphql-transport-ws: New ws protocol used by most Apollo Server instances
  /// with subscriptions enabled use this library.
  /// N.B: not to be confused with the graphql-ws library that implement the
  /// old ws protocol.
  static const String graphqlTransportWs = GraphQLProtocol.graphqlTransportWs;
}

/// ALL protocol supported by the library
class GraphQLProtocol {
  GraphQLProtocol._();

  /// graphql-ws: The new  (not to be confused with the graphql-ws library).
  /// NB. This protocol is it no longer maintained, please consider
  /// to use `SocketSubProtocol.graphqlTransportWs`.
  static const String graphqlWs = "graphql-ws";

  /// graphql-transport-ws: New ws protocol used by most Apollo Server instances
  /// with subscriptions enabled use this library.
  /// N.B: not to be confused with the graphql-ws library that implement the
  /// old ws protocol.
  static const String graphqlTransportWs = "graphql-transport-ws";
}

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
    this.protocol = GraphQLProtocol.graphqlWs,
    this.config = const SocketClientConfig(),
    @visibleForTesting this.randomBytesForUuid,
    @visibleForTesting this.onMessage,
    @visibleForTesting this.onStreamError = _defaultOnStreamError,
  }) {
    _connect();
  }

  Uint8List? randomBytesForUuid;
  final String url;
  final String protocol;
  final SocketClientConfig config;

  final BehaviorSubject<SocketConnectionState> _connectionStateController =
      BehaviorSubject<SocketConnectionState>();

  final HashMap<String, SubscriptionListener> _subscriptionInitializers =
      HashMap();

  bool _connectionWasLost = false;
  bool _wasDisposed = false;

  Timer? _reconnectTimer;
  Timer? _pingTimer;

  @visibleForTesting
  GraphQLWebSocketChannel? socketChannel;

  @visibleForTesting
  void Function(GraphQLSocketMessage)? onMessage;

  @visibleForTesting
  void Function(Object error, StackTrace stackTrace) onStreamError;

  Stream<GraphQLSocketMessage> get _messages => socketChannel!.messages;

  StreamSubscription<ConnectionKeepAlive>? _keepAliveSubscription;
  StreamSubscription<GraphQLSocketMessage>? _messageSubscription;

  Map<String, dynamic> Function(Request) get serialize =>
      config.serializer.serializeRequest;

  Response Function(Map<String, dynamic>) get parse =>
      config.parser.parseResponse;

  void _disconnectOnKeepAliveTimeout(Stream<GraphQLSocketMessage> messages) {
    _keepAliveSubscription = messages.whereType<ConnectionKeepAlive>().timeout(
      config.inactivityTimeout!,
      onTimeout: (EventSink<ConnectionKeepAlive> event) {
        event.close();
        unawaited(_closeSocketChannel());
      },
    ).listen(null);
  }

  Future<void> _closeSocketChannel() async {
    // avoid race condition in onCancel by setting socket connection
    // state to notConnected prior to closing socket. This ensures we don't
    // attempt to send a message over the channel that we're closing
    // if we are forcefully closing the socket
    if (!_connectionStateController.isClosed &&
        _connectionStateController.value !=
            SocketConnectionState.notConnected) {
      _connectionStateController.add(SocketConnectionState.notConnected);
    }
    await socketChannel?.sink.close(ws_status.normalClosure);
  }

  /// Connects to the server.
  ///
  /// If this instance is disposed, this method does nothing.
  Future<SocketClient> _connect() async {
    final InitOperation initOperation = await config.initOperation;

    if (_connectionStateController.isClosed || _wasDisposed) {
      return this;
    }

    _connectionStateController.add(SocketConnectionState.connecting);

    try {
      // Even though config.connect is sync, we call async in order to make the
      // SocketConnectionState.connected attribution not overload SocketConnectionState.connecting
      var connection =
          await config.connect(uri: Uri.parse(url), protocols: [protocol]);
      socketChannel = connection.forGraphQL();

      if (protocol == GraphQLProtocol.graphqlTransportWs) {
        _connectionStateController.add(SocketConnectionState.handshake);
      } else {
        _connectionStateController.add(SocketConnectionState.connected);
      }
      print('Initialising connection');
      _write(initOperation);
      if (protocol == GraphQLProtocol.graphqlTransportWs) {
        // wait for ack
        // this blocks to prevent ping from being called before ack is recieved
        await _messages.firstWhere(
            (message) => message.type == MessageTypes.connectionAck);
        _connectionStateController.add(SocketConnectionState.connected);
      }

      if (config.inactivityTimeout != null) {
        if (protocol == GraphQLProtocol.graphqlWs) {
          _disconnectOnKeepAliveTimeout(_messages);
        }
        if (protocol == GraphQLProtocol.graphqlTransportWs) {
          _enqueuePing();
        }
      }

      _messageSubscription = _messages.listen(
        (message) {
          if (onMessage != null) {
            onMessage!(message);
          }

          if (protocol == GraphQLProtocol.graphqlTransportWs) {
            if (message.type == 'ping') {
              _write(PongMessage());
            } else if (message.type == 'pong') {
              _enqueuePing();
            }
          }
        },
        onDone: onConnectionLost,
        // onDone will not be triggered if the subscription is
        // auto-cancelled on error; make sure to pass false
        cancelOnError: false,
        onError: onStreamError,
      );

      if (_connectionWasLost) {
        for (final s in _subscriptionInitializers.values) {
          s.callback();
        }

        _connectionWasLost = false;
      }
    } catch (e) {
      onConnectionLost(e);
    }
    return this;
  }

  void onConnectionLost([Object? e]) async {
    await _closeSocketChannel();
    if (e != null) {
      print('There was an error causing connection lost: $e');
    }
    print('Disconnected from websocket.');
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _keepAliveSubscription?.cancel();
    _messageSubscription?.cancel();

    if (_connectionStateController.isClosed || _wasDisposed) {
      return;
    }

    _connectionWasLost = true;
    _subscriptionInitializers.values.forEach((s) => s.hasBeenTriggered = false);

    if (config.autoReconnect &&
        !_connectionStateController.isClosed &&
        !_wasDisposed) {
      if (config.delayBetweenReconnectionAttempts != null) {
        _reconnectTimer = Timer(
          config.delayBetweenReconnectionAttempts!,
          () {
            _connect();
          },
        );
      } else {
        Timer.run(() => _connect());
      }
    }
  }

  void _enqueuePing() {
    _pingTimer?.cancel();
    _pingTimer = new Timer(
      config.inactivityTimeout!,
      () => _write(PingMessage()),
    );
  }

  /// Closes the underlying socket if connected, and stops reconnection attempts.
  /// After calling this method, this [SocketClient] instance must be considered
  /// unusable. Instead, create a new instance of this class.
  ///
  /// Use this method if you'd like to disconnect from the specified server permanently,
  /// and you'd like to connect to another server instead of the current one.
  Future<void> dispose() async {
    // Make sure we do not attempt to reconnect when we close the socket
    // and onConnectionLost is called (as part of onDone)
    _wasDisposed = true;
    print('Disposing socket client..');
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _keepAliveSubscription?.cancel();

    await Future.wait([
      _closeSocketChannel(),
      _messageSubscription?.cancel(),
      _connectionStateController.close(),
    ].where((future) => future != null).cast<Future<dynamic>>().toList());
  }

  void _write(final GraphQLSocketMessage message) {
    switch (_connectionStateController.value) {
      case SocketConnectionState.connected:
      case SocketConnectionState.handshake:
        socketChannel!.sink.add(
          json.encode(
            message,
            toEncodable: (dynamic m) => m.toJson(),
          ),
        );
        break;
      default:
        break;
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
    final String id = _uuid.v4(
      options: {
        'random': randomBytesForUuid,
      },
    ).toString();
    final StreamController<Response> response = StreamController<Response>();
    StreamSubscription<SocketConnectionState>? sub;
    final bool addTimeout =
        !payload.isSubscription && config.queryAndMutationTimeout != null;

    final onListen = () {
      final Stream<SocketConnectionState> waitForConnectedStateWithoutTimeout =
          (waitForConnection
                  ? _connectionStateController
                  : _connectionStateController
                      .startWith(SocketConnectionState.connected))
              .where((SocketConnectionState state) =>
                  state == SocketConnectionState.connected)
              .take(1);

      final Stream<SocketConnectionState> waitForConnectedState = addTimeout
          ? waitForConnectedStateWithoutTimeout.timeout(
              config.queryAndMutationTimeout!,
              onTimeout: (EventSink<SocketConnectionState> event) {
                print('Connection timed out.');
                response.addError(TimeoutException('Connection timed out.'));
                event.close();
                response.close();
              },
            )
          : waitForConnectedStateWithoutTimeout;

      sub = waitForConnectedState.listen((_) {
        final Stream<GraphQLSocketMessage> dataErrorComplete = _messages.where(
          (GraphQLSocketMessage message) {
            if (message is SubscriptionData) {
              return message.id == id;
            }

            if (message is SubscriptionNext) {
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
        ).takeWhile((_) => (!response.isClosed && !_wasDisposed));

        final Stream<GraphQLSocketMessage> subscriptionComplete = addTimeout
            ? dataErrorComplete
                .where((message) => message is SubscriptionComplete)
                .take(1)
                .timeout(
                config.queryAndMutationTimeout!,
                onTimeout: (EventSink<GraphQLSocketMessage> event) {
                  response.addError(TimeoutException('Request timed out.'));
                  event.close();
                  response.close();
                },
              )
            : dataErrorComplete
                .where((message) => message is SubscriptionComplete)
                .take(1);

        subscriptionComplete.listen(
          (_) => response.close(),
          onDone: () {
            if (!config.autoReconnect) {
              response.close();
            }
          },
          onError: (_) {
            if (!config.autoReconnect) {
              response.close();
            }
          },
        );

        dataErrorComplete
            .where((message) => message is SubscriptionData)
            .cast<SubscriptionData>()
            .listen((message) => response.add(
                  parse(message.toJson()),
                ));

        dataErrorComplete
            .where((message) => message is SubscriptionNext)
            .whereType<SubscriptionNext>()
            .listen((message) => response.add(
                  parse(message.toJson()),
                ));

        dataErrorComplete
            .where((message) => message is SubscriptionError)
            .cast<SubscriptionError>()
            .listen((message) => response.addError(message));

        if (!_subscriptionInitializers[id]!.hasBeenTriggered) {
          GraphQLSocketMessage operation = StartOperation(
            id,
            serialize(payload),
          );
          if (protocol == GraphQLProtocol.graphqlTransportWs) {
            operation = SubscribeOperation(
              id,
              serialize(payload),
            );
          }
          _write(operation);
          _subscriptionInitializers[id]!.hasBeenTriggered = true;
        }
      });
    };

    response.onListen = onListen;

    response.onCancel = () {
      _subscriptionInitializers.remove(id);

      sub?.cancel();
      if (protocol == GraphQLProtocol.graphqlWs &&
          _connectionStateController.value == SocketConnectionState.connected &&
          socketChannel != null) {
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
}

void _defaultOnStreamError(Object error, StackTrace st) {
  print('[SocketClient] message stream encountered error: $error\n'
      'stacktrace:\n${st.toString()}');
}

class GraphQLWebSocketChannel extends StreamChannelMixin<dynamic>
    implements WebSocketChannel {
  GraphQLWebSocketChannel(this._webSocket)
      : stream = _webSocket.stream.asBroadcastStream();

  WebSocketChannel _webSocket;

  Stream<dynamic> stream;
  Stream<GraphQLSocketMessage>? _messages;

  /// Stream of messages from the endpoint parsed as GraphQLSocketMessages
  Stream<GraphQLSocketMessage> get messages => _messages ??=
      stream.map<GraphQLSocketMessage>(GraphQLSocketMessage.parse);

  String? get protocol => _webSocket.protocol;

  int? get closeCode => _webSocket.closeCode;

  String? get closeReason => _webSocket.closeReason;

  @override
  WebSocketSink get sink => _webSocket.sink;
}

extension GraphQLGetter on WebSocketChannel {
  /// Returns a wrapper that has safety and convenience features for graphql
  GraphQLWebSocketChannel forGraphQL() => this is GraphQLWebSocketChannel
      ? this as GraphQLWebSocketChannel
      : GraphQLWebSocketChannel(this);
}
