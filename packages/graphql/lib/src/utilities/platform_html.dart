import 'package:graphql/src/links/websocket_link/websocket_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Future<WebSocketChannel> defaultConnectPlatform(
  Uri uri,
  Iterable<String>? protocols,
) async {
  final webSocketChannel =
      await WebSocketChannel.connect(uri, protocols: protocols);
  return webSocketChannel.forGraphQL();
}
