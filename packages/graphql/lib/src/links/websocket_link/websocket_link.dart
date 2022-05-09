import 'package:gql_exec/gql_exec.dart';
import 'package:gql_link/gql_link.dart';

import './websocket_client.dart';

export './websocket_client.dart';
export './websocket_messages.dart';

/// A Universal Websocket [Link] implementation to support the websocket transport.
/// It supports subscriptions, query and mutation operations as well.
///
/// NOTE: the actual socket connection will only get established after a [Request] is handled by this [WebSocketLink].
/// If you'd like to connect to the socket server instantly, call the [connectOrReconnect] method after creating this [WebSocketLink] instance.
class WebSocketLink extends Link {
  /// Creates a new [WebSocketLink] instance with the specified config.
  WebSocketLink(
    this.url, {
    this.config = const SocketClientConfig(),
    this.subProtocol = SocketSubProtocol.graphqlWs,
  });

  final String url;
  final String subProtocol;
  final SocketClientConfig config;

  // cannot be final because we're changing the instance upon a header change.
  SocketClient? _socketClient;

  @override
  Stream<Response> request(Request request, [forward]) async* {
    if (_socketClient == null) {
      connectOrReconnect();
    }

    yield* _socketClient!.subscribe(request, true);
  }

  /// Connects or reconnects to the server with the specified headers.
  void connectOrReconnect() {
    _socketClient?.dispose();
    _socketClient = SocketClient(
      url,
      config: config,
      protocol: subProtocol,
    );
  }

  /// Disposes the underlying socket client explicitly. Only use this, if you want to disconnect from
  /// the current server in favour of another one. If that's the case, create a new [WebSocketLink] instance.
  Future<void> dispose() async {
    await _socketClient?.dispose();
    _socketClient = null;
  }
}
