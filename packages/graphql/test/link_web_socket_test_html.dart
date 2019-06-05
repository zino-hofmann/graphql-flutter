@TestOn('browser')

import 'package:test/test.dart';
import 'package:graphql/src/link/web_socket/link_web_socket.dart';

void main() {
  group('Link Websocket', () {
    test('simple connection', () {
      expect(
          () => WebSocketLink(
                url: 'ws://echo.websocket.org',
                // ignore: deprecated_member_use_from_same_package
                headers: {'foo': 'bar'},
              ),
          throwsA(TypeMatcher<AssertionError>()));
    });
  });
}
