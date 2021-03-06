import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:graphql/src/links/gql_links.dart';
import 'package:meta/meta.dart';

import 'package:graphql/src/core/query_options.dart' show WithType;
import 'package:gql_exec/gql_exec.dart';

import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/uuid_util.dart';

import './websocket_messages.dart';

typedef GetInitPayload = FutureOr<dynamic> Function();

/// A definition for functions that returns a connected [WebSocketChannel]
typedef WebSocketConnect = WebSocketChannel Function(
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

enum SocketConnectionState { notConnected, connecting, connected }

class SocketClientConfig {
  const SocketClientConfig({
    this.serializer = const RequestSerializer(),
    this.parser = const ResponseParser(),
    this.autoReconnect = true,
    this.queryAndMutationTimeout = const Duration(seconds: 10),
    this.inactivityTimeout = const Duration(seconds: 30),
    this.delayBetweenReconnectionAttempts = const Duration(seconds: 5),
    this.initialPayload,
    @experimental this.connect = defaultConnect,
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
  /// Warning: if you want to listen to the listen to the stream,
  /// wrap your channel with our [GraphQLWebSocketChannel] using the `.forGraphQL()` helper:
  /// ```dart
  /// connect: (url, protocols) {
  ///    var channel = WebSocketChannel.connect(url, protocols: protocols)
  ///    // without this line, our client won't be able to listen to stream events,
  ///    // because you are already listening.
  ///    channel = channel.forGraphQL();
  ///    channel.stream.listen(myListener)
  ///    return channel;
  /// }
  /// ```
  ///
  /// To supply custom headers to an IO client:
  /// ```dart
  /// connect: (url, protocols) =>
  ///   IOWebSocketChannel.connect(url, protocols: protocols, headers: myCustomHeaders)
  /// ```
  final WebSocketConnect connect;

  static WebSocketChannel defaultConnect(
    Uri uri,
    Iterable<String>? protocols,
  ) =>
      WebSocketChannel.connect(uri, protocols: protocols).forGraphQL();

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
    this.protocols = const ['graphql-ws'],
    WebSocketConnect? connect,
    this.config = const SocketClientConfig(),
    @visibleForTesting this.randomBytesForUuid,
    @visibleForTesting this.onMessage,
    @visibleForTesting this.onStreamError = _defaultOnStreamError,
  }) {
    _connect();
  }

  Uint8List? randomBytesForUuid;
  final String url;
  final Iterable<String>? protocols;
  final SocketClientConfig config;

  final BehaviorSubject<SocketConnectionState> _connectionStateController =
      BehaviorSubject<SocketConnectionState>();

  final HashMap<String, SubscriptionListener> _subscriptionInitializers =
      HashMap();

  bool _connectionWasLost = false;

  Timer? _reconnectTimer;

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
        print(
          "Haven't received keep alive message for ${config.inactivityTimeout!.inSeconds} seconds. Disconnecting..",
        );
        event.close();
        socketChannel!.sink.close(ws_status.goingAway);
        _connectionStateController.add(SocketConnectionState.notConnected);
      },
    ).listen(null);
  }

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
      // Even though config.connect is sync, we call async in order to make the
      // SocketConnectionState.connected attribution not overload SocketConnectionState.connecting
      socketChannel =
          await config.connect(Uri.parse(url), protocols).forGraphQL();
      _connectionStateController.add(SocketConnectionState.connected);
      print('Connected to websocket.');
      _write(initOperation);

      if (config.inactivityTimeout != null) {
        _disconnectOnKeepAliveTimeout(_messages);
      }

      _messageSubscription = _messages.listen(
        onMessage,
        onDone: onConnectionLost,
        cancelOnError: true,
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
  }

  void onConnectionLost([e]) {
    socketChannel?.sink.close(ws_status.goingAway);
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
          'Scheduling to connect in ${config.delayBetweenReconnectionAttempts!.inSeconds} seconds...',
        );

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
      socketChannel?.sink.close(ws_status.goingAway),
      _messageSubscription?.cancel(),
      _connectionStateController.close(),
    ].where((future) => future != null).cast<Future<dynamic>>().toList());
  }

  void _write(final GraphQLSocketMessage message) {
    if (_connectionStateController.value == SocketConnectionState.connected) {
      socketChannel!.sink.add(
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
                config.queryAndMutationTimeout!,
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

        if (!_subscriptionInitializers[id]!.hasBeenTriggered) {
          _write(
            StartOperation(
              id,
              serialize(payload),
            ),
          );
          _subscriptionInitializers[id]!.hasBeenTriggered = true;
        }
      });
    };

    response.onListen = onListen;

    response.onCancel = () {
      _subscriptionInitializers.remove(id);

      sub?.cancel();
      if (_connectionStateController.value == SocketConnectionState.connected &&
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
  print('[SocketClient] message stream ecnountered error: $error\n'
      'stacktrace:\n${st.toString()}');
}

class GraphQLWebSocketChannel extends StreamChannelMixin
    implements WebSocketChannel {
  GraphQLWebSocketChannel(this._webSocket)
      : stream = _webSocket.stream.asBroadcastStream();

  WebSocketChannel _webSocket;

  Stream stream;
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
