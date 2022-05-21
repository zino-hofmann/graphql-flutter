/// Web Socket echo server
/// to run the test and cover the web socket test
///
/// author: https://github.com/vincenzopalazzo
import 'dart:convert';
import 'dart:io';

const String forceDisconnectCommand = '___force_disconnect___';

/// Main function to create and run the echo server over the web socket.
Future<String> runWebSocketServer(
    {String host = "127.0.0.1", int port = 5600}) async {
  HttpServer server = await HttpServer.bind(host, port);
  server.transform(WebSocketTransformer()).listen(onWebSocketData);
  return "ws://$host:$port";
}

/// Handle event received on server.
void onWebSocketData(WebSocket client) {
  client.listen((data) async {
    if (data == forceDisconnectCommand) {
      client.close(WebSocketStatus.normalClosure, 'shutting down');
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
