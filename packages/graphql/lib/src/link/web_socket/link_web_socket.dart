import 'package:gql/execution.dart';
import 'package:gql/link.dart';
import 'package:gql_http_link/gql_http_link.dart';
import 'package:graphql/src/socket_client.dart';
import 'package:graphql/src/websocket/messages.dart';
import 'package:meta/meta.dart';

/// A Universal Websocket [Link] implementation to support the websocket transport.
/// It supports subscriptions, query and mutation operations as well.
///
/// NOTE: the actual socket connection will only get established after an [Operation] is handled by this [WebSocketLink].
/// If you'd like to connect to the socket server instantly, call the [connectOrReconnect] method after creating this [WebSocketLink] instance.
class WebSocketLink extends HttpLink {
  final String url;
  final SocketClientConfig config;

  // cannot be final because we're changing the instance upon a header change.
  SocketClient _socketClient;

  /// Creates a new [WebSocketLink] instance with the specified config.
  WebSocketLink({
    @required this.url,
    this.config = const SocketClientConfig(),
  }) : super(url);

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

  @override
  Stream<Response> request(
    Request request, [
    NextLink forward,
  ]) {
    if (_socketClient == null) {
      connectOrReconnect();
    }

    return _socketClient
        .subscribe(
          SubscriptionRequest(request),
          true,
        )
        .map(
          (SubscriptionData result) => parseResponse(
            <String, dynamic>{
              'data': result.data,
              'errors': result.errors,
            },
          ),
        );
  }
}
