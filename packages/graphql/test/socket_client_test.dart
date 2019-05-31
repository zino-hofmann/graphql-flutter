import 'package:test/test.dart';
// import 'dart:html' show WebSocket, querySelector;
import 'package:graphql/src/socket_client.dart'
    show SocketClient, SocketConnectionState;

void main() {
  group('SocketClient', () {
    test('connection', () async {
      final c = SocketClient('ws://echo.websocket.org');
      await expectLater(
        c.connectionState.asBroadcastStream(),
        emitsInOrder(
          [
            SocketConnectionState.CONNECTING,
            SocketConnectionState.CONNECTED,
          ],
        ),
      );
      await c.dispose();
    }, tags: "integration");
  });
}
