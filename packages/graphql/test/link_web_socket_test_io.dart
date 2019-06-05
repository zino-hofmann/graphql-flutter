@TestOn('vm')

import 'package:test/test.dart';
import 'package:graphql/src/link/web_socket/link_web_socket.dart';

import 'helpers.dart';

void main() {
  group('Link Websocket', () {
    test('simple connection', overridePrint((List<String> log) {
      WebSocketLink(
        url: 'ws://echo.websocket.org',
        // ignore: deprecated_member_use_from_same_package
        headers: {'foo': 'bar'},
      );
      expect(log, [
        'Cannot set websocket headers with dart:html websockets. '
            'If these are for authentication, another approach must be used, '
            'such as initPayload.'
      ]);
    }));
  });
}
