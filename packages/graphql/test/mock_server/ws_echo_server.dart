/// Web Socket echo server
/// to run the test and cover the web socket test
///
/// author: https://github.com/vincenzopalazzo
import 'dart:convert';
import 'dart:io';

const String forceDisconnectCommand = '___force_disconnect___';
const String forceAuthDisconnectCommand = '___force_auth_disconnect___';

/// Headers from the most recent websocket handshake.
HttpHeaders? lastHandshakeHeaders;

/// Main function to create and run the echo server over the web socket.
Future<String> runWebSocketServer(
    {String host = "127.0.0.1", int port = 5600}) async {
  HttpServer server = await HttpServer.bind(host, port);
  server.listen((HttpRequest request) async {
    lastHandshakeHeaders = request.headers;
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final WebSocket client = await WebSocketTransformer.upgrade(request);
      onWebSocketData(client);
    } else {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
    }
  });
  return "ws://$host:$port";
}

/// Handle event received on server.
void onWebSocketData(WebSocket client) {
  client.listen((data) async {
    if (data == forceDisconnectCommand) {
      client.close(WebSocketStatus.normalClosure, 'shutting down');
    } else if (data == forceAuthDisconnectCommand) {
      client.close(4001, 'Unauthorized');
    } else {
      final message = json.decode(data.toString());
      if (message['type'] == 'connection_init' &&
          message['payload']?['protocol'] == 'graphql-transport-ws') {
        client.add(json.encode({
          'type': 'connection_ack',
          'payload': null,
        }));
      } else {
        client.add(data);
      }
    }
  });
}
