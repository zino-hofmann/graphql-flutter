import 'package:test/test.dart';

import 'package:graphql/legacy_socket_api/legacy_socket_link.dart';
import 'package:graphql/legacy_socket_api/legacy_socket_client.dart';

import 'helpers.dart';

void main() {
  group('Link Websocket', () {
    test('simple connection', overridePrint((List<String> log) {
      // ignore: deprecated_member_use_from_same_package
      WebSocketLink(
        url: 'ws://echo.websocket.org',
        // ignore: deprecated_member_use_from_same_package
        headers: {'foo': 'bar'},
      );
      expect(log, [
        'WARNING: Using direct websocket headers which will be removed soon, '
            'as it is incompatable with dart:html. '
            'If you need this direct header access, '
            'please comment on this PR with details on your usecase: '
            'https://github.com/zino-app/graphql-flutter/pull/323'
      ]);
    }));
  });

  group('LegacyInitOperation', () {
    test('null payload', () {
      // ignore: deprecated_member_use_from_same_package
      final operation = LegacyInitOperation(null);
      expect(operation.toJson(), {'type': 'connection_init'});
    });
    test('simple payload', () {
      // ignore: deprecated_member_use_from_same_package
      final operation = LegacyInitOperation(42);
      expect(operation.toJson(), {'type': 'connection_init', 'payload': '42'});
    });
    test('complex payload', () {
      // ignore: deprecated_member_use_from_same_package
      final operation = LegacyInitOperation({
        'value': 42,
        'nested': {
          'number': [3, 7],
          'string': ['foo', 'bar']
        }
      });
      expect(operation.toJson(), {
        'type': 'connection_init',
        'payload':
            '{"value":42,"nested":{"number":[3,7],"string":["foo","bar"]}}'
      });
    });
  });
}
