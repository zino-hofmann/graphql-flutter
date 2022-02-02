import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:gql/language.dart';
import 'package:graphql/client.dart';

import './helpers.dart';
import './mock_server/ws_echo_server.dart';
import 'mock_server/ws_echo_server.dart';

SocketClient getTestClient(
        {required String wsUrl,
        StreamController? controller,
        bool autoReconnect = true,
        Map<String, dynamic>? customHeaders,
        Duration delayBetweenReconnectionAttempts =
            const Duration(milliseconds: 1)}) =>
    SocketClient(
      wsUrl,
      config: SocketClientConfig(
        autoReconnect: autoReconnect,
        headers: customHeaders,
        delayBetweenReconnectionAttempts: delayBetweenReconnectionAttempts,
      ),
      randomBytesForUuid: Uint8List.fromList(
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
      ),
    );

Future<void> main() async {
  String wsUrl = await runWebSocketServer();
  group('InitOperation', () {
    test('null payload', () {
      // ignore: deprecated_member_use_from_same_package
      final operation = InitOperation(null);
      expect(operation.toJson(), {'type': 'connection_init'});
    });
    test('simple payload', () {
      // ignore: deprecated_member_use_from_same_package
      final operation = InitOperation(42);
      expect(operation.toJson(), {'type': 'connection_init', 'payload': 42});
    });
    test('complex payload', () {
      // ignore: deprecated_member_use_from_same_package
      final operation = InitOperation({
        'value': 42,
        'nested': {
          'number': [3, 7],
          'string': ['foo', 'bar']
        }
      });
      expect(operation.toJson(), {
        'type': 'connection_init',
        'payload': {
          'value': 42,
          'nested': {
            'number': [3, 7],
            'string': ['foo', 'bar']
          }
        }
      });
    });
  });

  group('SocketClient without payload', () {
    late SocketClient socketClient;
    StreamController controller;
    final expectedMessage = r'{'
        r'"type":"start","id":"01020304-0506-4708-890a-0b0c0d0e0f10",'
        r'"payload":{"operationName":null,"variables":{},"query":"subscription {\n  \n}"}'
        r'}';
    setUp(overridePrint((log) {
      controller = StreamController(sync: true);
      socketClient = getTestClient(controller: controller, wsUrl: wsUrl);
    }));
    tearDown(overridePrint(
      (log) => socketClient.dispose(),
    ));
    test('connection', () async {
      await expectLater(
        socketClient.connectionState.asBroadcastStream(),
        emitsInOrder(
          [
            SocketConnectionState.connecting,
            SocketConnectionState.connected,
          ],
        ),
      );
    });
    test('disconnect via dispose', () async {
      // First wait for connection to complete
      await expectLater(
        socketClient.connectionState.asBroadcastStream(),
        emitsInOrder(
          [
            SocketConnectionState.connecting,
            SocketConnectionState.connected,
          ],
        ),
      );

      // We need to begin waiting on the connectionState
      // before we issue the command to disconnect; otherwise
      // it can reconnect so fast that it will be reconnected
      // by the time that the expectLater check is initiated.
      await overridePrint((_) async {
        Timer(const Duration(milliseconds: 20), () async {
          await socketClient.dispose();
        });
      })();
      // The connectionState BehaviorController emits the current state
      // to any new listener, so we expect it to start in the connected
      // state and transition to notConnected because of dispose.
      await expectLater(
        socketClient.connectionState,
        emitsInOrder([
          SocketConnectionState.connected,
          SocketConnectionState.notConnected,
        ]),
      );

      // Have to wait for socket close to be fully processed after we reach
      // the notConnected state, including updating channel with close code.
      await Future.delayed(const Duration(milliseconds: 20));

      // The websocket should be in a fully closed state at this point,
      // we should have a confirmed close code in the channel.
      expect(socketClient.socketChannel, isNotNull);
      expect(socketClient.socketChannel!.closeCode, isNotNull);
    });
    test('subscription data', () async {
      final payload = Request(
        operation: Operation(document: parseString('subscription {}')),
      );
      final waitForConnection = true;
      final subscriptionDataStream =
          socketClient.subscribe(payload, waitForConnection);
      await socketClient.connectionState
          .where((state) => state == SocketConnectionState.connected)
          .first;

      // ignore: unawaited_futures
      socketClient.socketChannel!.stream
          .where((message) => message == expectedMessage)
          .first
          .then((_) {
        socketClient.socketChannel!.sink.add(jsonEncode({
          'type': 'data',
          'id': '01020304-0506-4708-890a-0b0c0d0e0f10',
          'payload': {
            'data': {'foo': 'bar'},
            'errors': [
              {'message': 'error and data can coexist'}
            ]
          }
        }));
      });

      await expectLater(
        subscriptionDataStream,
        emits(
          // todo should ids be included in response context? probably '01020304-0506-4708-890a-0b0c0d0e0f10'
          Response(
            data: {'foo': 'bar'},
            errors: [
              GraphQLError(message: 'error and data can coexist'),
            ],
            context: Context().withEntry(ResponseExtensions(null)),
          ),
        ),
      );
    });
    test('resubscribe', () async {
      final payload = Request(
        operation: Operation(document: gql('subscription {}')),
      );
      final waitForConnection = true;
      final subscriptionDataStream =
          socketClient.subscribe(payload, waitForConnection);

      await expectLater(
        socketClient.connectionState,
        emitsInOrder([
          SocketConnectionState.connecting,
          SocketConnectionState.connected,
        ]),
      );

      await overridePrint((_) async {
        socketClient.onConnectionLost();
      })();

      await expectLater(
        socketClient.connectionState,
        emitsInOrder([
          SocketConnectionState.notConnected,
          SocketConnectionState.connecting,
          SocketConnectionState.connected,
        ]),
      );

      // ignore: unawaited_futures
      socketClient.socketChannel!.stream
          .where((message) => message == expectedMessage)
          .first
          .then((_) {
        socketClient.socketChannel!.sink.add(jsonEncode({
          'type': 'data',
          'id': '01020304-0506-4708-890a-0b0c0d0e0f10',
          'payload': {
            'data': {'foo': 'bar'},
            'errors': [
              {'message': 'error and data can coexist'}
            ]
          }
        }));
      });

      await expectLater(
        subscriptionDataStream,
        emits(
          // todo should ids be included in response context? probably '01020304-0506-4708-890a-0b0c0d0e0f10'
          Response(
            data: {'foo': 'bar'},
            errors: [
              GraphQLError(message: 'error and data can coexist'),
            ],
            context: Context().withEntry(ResponseExtensions(null)),
          ),
        ),
      );
    });
    test('resubscribe after server disconnect', () async {
      final payload = Request(
        operation: Operation(document: gql('subscription {}')),
      );
      final waitForConnection = true;
      final subscriptionDataStream =
          socketClient.subscribe(payload, waitForConnection);

      await expectLater(
        socketClient.connectionState,
        emitsInOrder([
          SocketConnectionState.connecting,
          SocketConnectionState.connected,
        ]),
      );

      // We need to begin waiting on the connectionState
      // before we issue the command to disconnect; otherwise
      // it can reconnect so fast that it will be reconnected
      // by the time that the expectLater check is initiated.
      Timer(const Duration(milliseconds: 20), () async {
        socketClient.socketChannel!.sink.add(forceDisconnectCommand);
      });
      // The connectionState BehaviorController emits the current state
      // to any new listener, so we expect it to start in the connected
      // state, transition to notConnected, and then reconnect after that.
      await expectLater(
        socketClient.connectionState,
        emitsInOrder([
          SocketConnectionState.connected,
          SocketConnectionState.notConnected,
          SocketConnectionState.connecting,
          SocketConnectionState.connected,
        ]),
      );

      // ignore: unawaited_futures
      socketClient.socketChannel!.stream
          .where((message) => message == expectedMessage)
          .first
          .then((_) {
        socketClient.socketChannel!.sink.add(jsonEncode({
          'type': 'data',
          'id': '01020304-0506-4708-890a-0b0c0d0e0f10',
          'payload': {
            'data': {'foo': 'bar'},
            'errors': [
              {'message': 'error and data can coexist'}
            ]
          }
        }));
      });

      await expectLater(
        subscriptionDataStream,
        emits(
          // todo should ids be included in response context? probably '01020304-0506-4708-890a-0b0c0d0e0f10'
          Response(
            data: {'foo': 'bar'},
            errors: [
              GraphQLError(message: 'error and data can coexist'),
            ],
            context: Context().withEntry(ResponseExtensions(null)),
          ),
        ),
      );
    });
  }, tags: "integration");

  group('SocketClient without autoReconnect', () {
    late SocketClient socketClient;
    StreamController controller;
    setUp(overridePrint((log) {
      controller = StreamController(sync: true);
      socketClient = getTestClient(
          controller: controller, wsUrl: wsUrl, autoReconnect: false);
    }));
    tearDown(overridePrint(
      (log) => socketClient.dispose(),
    ));
    test('server disconnect', () async {
      final payload = Request(
        operation: Operation(document: gql('subscription {}')),
      );
      final waitForConnection = true;
      socketClient.subscribe(payload, waitForConnection);

      await expectLater(
        socketClient.connectionState,
        emitsInOrder([
          SocketConnectionState.connecting,
          SocketConnectionState.connected,
        ]),
      );

      Timer(const Duration(milliseconds: 20), () async {
        socketClient.socketChannel!.sink.add(forceDisconnectCommand);
      });
      // Same strategy as elsewhere, start expecting the state on the
      // stream before the disconnect actually happens...
      await expectLater(
        socketClient.connectionState,
        emitsInOrder([
          SocketConnectionState.connected,
          SocketConnectionState.notConnected,
        ]),
      );

      expect(
          socketClient.socketChannel!.closeCode, WebSocketStatus.normalClosure);
    });
  }, tags: "integration");

  group('SocketClient with const payload', () {
    late SocketClient socketClient;
    const initPayload = {'token': 'mytoken'};

    setUp(overridePrint((log) {
      socketClient = SocketClient(
        wsUrl,
        config: SocketClientConfig(initialPayload: () => initPayload),
      );
    }));

    tearDown(overridePrint(
      (log) => expectLater(
        socketClient.dispose().timeout(Duration(seconds: 1)),
        completion(null),
      ),
    ));

    test('connection', () async {
      await socketClient.connectionState
          .where((state) => state == SocketConnectionState.connected)
          .first;

      await expectLater(
          socketClient.socketChannel!.stream.map((s) {
            return jsonDecode(s)['payload'];
          }),
          emits(initPayload));
    });
  });

  group('SocketClient with future payload', () {
    late SocketClient socketClient;
    const initPayload = {'token': 'mytoken'};

    setUp(overridePrint((log) {
      socketClient = SocketClient(
        wsUrl,
        config: SocketClientConfig(
          initialPayload: () async {
            await Future.delayed(Duration(seconds: 3));
            return initPayload;
          },
        ),
      );
    }));

    tearDown(overridePrint((log) async {
      await socketClient.dispose();
    }));

    test('connection', () async {
      await socketClient.connectionState
          .where((state) => state == SocketConnectionState.connected)
          .first;

      await expectLater(
        socketClient.socketChannel!.stream.map((s) {
          return jsonDecode(s)['payload'];
        }),
        emits(initPayload),
      );
    });

    /*
    FIXME: Testing the correct header in the request
    group('SocketClient with custom headers with const payload', () {
      const customHeaders = {'myHeader': 'myHeader'};

      setUp(overridePrint((log) {
        socketClient = getTestClient(wsUrl: wsUrl, customHeaders: customHeaders);
      }));

      test('check header', () async {
        await socketClient.connectionState
            .where((state) => state == SocketConnectionState.notConnected)
            .first;
      });
    });
    */
  });
}
