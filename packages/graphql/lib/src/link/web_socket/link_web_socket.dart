import 'package:meta/meta.dart';

import 'package:graphql/src/link/fetch_result.dart';
import 'package:graphql/src/link/link.dart';
import 'package:graphql/src/link/operation.dart';
import 'package:graphql/src/socket_client.dart';
import 'package:graphql/src/websocket/messages.dart';

/// A Universal Websocket [Link] implementation to support the websocket transport.
/// It supports subscriptions, query and mutation operations as well.
///
/// NOTE: the actual socket connection will only get established after an [Operation] is handled by this [WebSocketLink].
/// If you'd like to connect to the socket server instantly, call the [connectOrReconnect] method after creating this [WebSocketLink] instance.
class WebSocketLink extends Link {
  /// Creates a new [WebSocketLink] instance with the specified config.
  WebSocketLink({
    @required this.url,
    this.config = const SocketClientConfig(),
  }) : super() {
    request = _doOperation;
  }

  final String url;
  final SocketClientConfig config;

  // cannot be final because we're changing the instance upon a header change.
  SocketClient _socketClient;

  Stream<FetchResult> _doOperation(Operation operation, [NextLink forward]) {
    if (_socketClient == null) {
      connectOrReconnect();
    }

    return _socketClient.subscribe(SubscriptionRequest(operation), true).map(
          (SubscriptionData result) => FetchResult(
              data: result.data,
              errors: result.errors as List<dynamic>,
              context: operation.getContext(),
              extensions: operation.extensions),
        );
  }

  /// Connects or reconnects to the server with the specified headers.
  void connectOrReconnect() {
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
