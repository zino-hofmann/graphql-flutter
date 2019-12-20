@TestOn('vm')

import 'dart:convert';
import 'dart:typed_data';

import 'package:gql/language.dart';
import 'package:test/test.dart';

import 'package:graphql/src/link/operation.dart';
import 'package:graphql/src/websocket/messages.dart';

import 'package:graphql/legacy_socket_api/legacy_socket_client.dart';

import 'helpers.dart';

void main() {
  group(
    'SocketClient',
    () {
      // ignore: deprecated_member_use_from_same_package
      SocketClient socketClient;
      setUp(overridePrint((log) {
        // ignore: deprecated_member_use_from_same_package
        socketClient = SocketClient(
          'ws://echo.websocket.org',
          protocols: null,
          randomBytesForUuid: Uint8List.fromList(
              [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]),
        );
      }));
      tearDown(overridePrint((log) async {
        await socketClient.dispose();
      }));
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
        final payload = SubscriptionRequest(
          Operation(documentNode: parseString('subscription {}')),
        );
        final waitForConnection = true;
        final subscriptionDataStream =
            socketClient.subscribe(payload, waitForConnection);
        await socketClient.connectionState
            .where((state) => state == SocketConnectionState.CONNECTED)
            .first;

        // ignore: unawaited_futures
        socketClient.stream
            .where(
              (message) =>
                  message ==
                  r'{"type":"start","id":"01020304-0506-4708-890a-0b0c0d0e0f10","payload":{"operationName":null,"query":"subscription {\n  \n}","variables":{}}}',
            )
            .first
            .then(
          (_) {
            socketClient.socket.add(
              jsonEncode({
                'type': 'data',
                'id': '01020304-0506-4708-890a-0b0c0d0e0f10',
                'payload': {
                  'data': {'foo': 'bar'},
                  'errors': ['error and data can coexist']
                }
              }),
            );
          },
        );

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
    },
    tags: "integration",
    onPlatform: {
      "!vm": Skip("This test is only for VM"),
    },
  );
}
