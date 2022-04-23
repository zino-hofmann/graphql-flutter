import 'package:graphql/src/links/websocket_link/websocket_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Future<WebSocketChannel> defaultConnectPlatform(
    Uri uri, Iterable<String>? protocols,
    {Map<String, dynamic>? headers}) async {
  if (headers != null) {
    print("The headers on the web are not supported");
  }
  final webSocketChannel = WebSocketChannel.connect(
    uri,
    protocols: protocols,
  );
  return webSocketChannel.forGraphQL();
}
