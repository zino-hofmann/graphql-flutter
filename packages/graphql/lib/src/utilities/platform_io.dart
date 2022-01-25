import 'dart:io';

import 'package:graphql/src/links/websocket_link/websocket_client.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Future<WebSocketChannel> defaultConnectPlatform(
    Uri uri, Iterable<String>? protocols,
    {Map<String, dynamic>? headers}) async {
  final webSocket = await WebSocket.connect(uri.toString(),
      protocols: protocols, headers: headers);
  return IOWebSocketChannel(webSocket).forGraphQL();
}
