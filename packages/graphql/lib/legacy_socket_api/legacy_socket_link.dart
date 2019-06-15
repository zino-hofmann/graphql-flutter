import 'package:meta/meta.dart';
import 'package:graphql/src/link/fetch_result.dart';
import 'package:graphql/src/link/link.dart';
import 'package:graphql/src/link/operation.dart';
import 'package:graphql/src/socket_client.dart';
import 'package:graphql/src/websocket/messages.dart';

/// @deprecated Old SocketClient that accepts and handles headers.
/// WebSocket headers are not usable in the browser.
/// So, to encourage universality,
/// they are not usable in the main socket link and client any longer
///
/// A websocket [Link] implementation to support the websocket transport.
/// It supports subscriptions, query and mutation operations as well.
///
/// This link is aware of [AuthLink], so the headers specified there are automatically
/// applied when connecting to the socket server, unless explicitly overridden by the [headers]
/// parameter.
///
/// There's an option called [reconnectOnHeaderChange] that makes it possible to reconnect to the server when the
/// headers have changed. For example, if the user logs in with another user account and the `Authorization` header changes.
/// This could be desired because of the nature of websocket connections: headers can only be specified upon connecting.
///
/// NOTE: the actual socket connection will only get established after an [Operation] is handled by this [WebSocketLink].
/// If you'd like to connect to the socket server instantly, call the [connectOrReconnect] method after creating this [WebSocketLink] instance.
@deprecated
class WebSocketLink extends Link {
  /// Creates a new [WebSocketLink] instance with the specified config.
  WebSocketLink({
    @required this.url,
    this.headers,
    this.reconnectOnHeaderChange = true,
    this.config = const SocketClientConfig(),
  }) : super() {
    if (headers != null) {
      print(
        'WARNING: Using direct websocket headers which will be removed soon, '
        'as it is incompatable with dart:html. '
        'If you need this direct header access, '
        'please comment on this PR with details on your usecase: '
        'https://github.com/zino-app/graphql-flutter/pull/323',
      );
    } else {
      print(
        'WARNING: You are using the deprecated websocket API, '
        'but do not appear to need direct header access. '
        'If you also do not need the legacyInitPayload, '
        'please switch to the new link and client',
      );
    }
    request = _doOperation;
  }

  final String url;
  final Map<String, dynamic> headers;
  final bool reconnectOnHeaderChange;
  final SocketClientConfig config;

  // cannot be final because we're changing the instance upon a header change.
  SocketClient _socketClient;

  Stream<FetchResult> _doOperation(Operation operation, [NextLink forward]) {
    final Map<String, dynamic> concatHeaders = <String, dynamic>{};
    final Map<String, dynamic> context = operation.getContext();
    if (context != null && context.containsKey('headers')) {
      concatHeaders.addAll(context['headers'] as Map<String, dynamic>);
    }
    // @todo deprecated
    if (headers != null) {
      concatHeaders.addAll(headers);
    }

    if (_socketClient == null) {
      connectOrReconnect(headers: concatHeaders);
    }

    return _socketClient.subscribe(SubscriptionRequest(operation), true).map(
        (SubscriptionData result) => FetchResult(
            data: result.data,
            errors: result.errors as List<dynamic>,
            context: operation.getContext(),
            extensions: operation.extensions));
  }

  /// Connects or reconnects to the server with the specified headers.
  void connectOrReconnect({Map<String, dynamic> headers}) {
    _socketClient?.dispose();
    _socketClient = SocketClient(url, config: config);
  }

  /// Disposes the underlying socket client explicitly. Only use this, if you want to disconnect from
  /// the current server in favour of another one. If that's the case, create a new [WebSocketLink] instance.
  Future<void> dispose() async {
    await _socketClient?.dispose();
    _socketClient = null;
  }
}
