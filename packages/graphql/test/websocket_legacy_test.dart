@TestOn('vm')

import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:graphql/src/link/operation.dart';
import 'package:graphql/src/websocket/messages.dart';

import 'package:graphql/legacy_socket_api/legacy_socket_link.dart';
import 'package:graphql/legacy_socket_api/legacy_socket_client.dart';

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

  group('SocketClient', () {
    SocketClient socketClient;
    setUp(() {
      socketClient = SocketClient(
        'ws://echo.websocket.org',
        protocols: null,
        randomBytesForUuid: Uint8List.fromList(
            [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]),
      );
    });
    tearDown(() async {
      await socketClient.dispose();
    });
    test('connection', () async {
      await expectLater(
        socketClient.connectionState.asBroadcastStream(),
        emitsInOrder(
          [
            SocketConnectionState.CONNECTING,
            SocketConnectionState.CONNECTED,
          ],
        ),
      );
    });
    test('subscription data', () async {
      final payload = SubscriptionRequest(Operation(document: 'empty'));
      final waitForConnection = true;
      final subscriptionDataStream =
          socketClient.subscribe(payload, waitForConnection);
      await socketClient.connectionState
          .where((state) => state == SocketConnectionState.CONNECTED)
          .first;

      // ignore: unawaited_futures
      socketClient.stream
          .where((message) =>
              message ==
              '{"type":"start","id":"01020304-0506-4708-890a-0b0c0d0e0f10","payload":{"operationName":null,"query":"empty","variables":{}}}')
          .first
          .then((_) {
        socketClient.socket.add(jsonEncode({
          'type': 'data',
          'id': '01020304-0506-4708-890a-0b0c0d0e0f10',
          'payload': {
            'data': {'foo': 'bar'},
            'errors': ['error and data can coexist']
          }
        }));
      });

      await expectLater(
        subscriptionDataStream,
        emits(
          SubscriptionData(
            '01020304-0506-4708-890a-0b0c0d0e0f10',
            {'foo': 'bar'},
            ['error and data can coexist'],
          ),
        ),
      );
    });
  }, tags: "integration");
}
