import 'dart:async';
import 'package:rxdart/subjects.dart';
import 'package:test/test.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:gql/language.dart';
import 'package:graphql/client.dart';
import 'package:graphql/src/links/websocket_link/websocket_client.dart';
import 'package:graphql/src/links/websocket_link/websocket_messages.dart';
import 'package:websocket/websocket.dart';

import './helpers.dart';

class EchoSocket implements WebSocket {
  EchoSocket() : controller = BehaviorSubject();

  static Future<WebSocket> connect(
    String url, {
    Iterable<String> protocols,
  }) async =>
      EchoSocket();

  StreamController controller;

  int closeCode;
  String closeReason;

  void add(/*String|List<int>*/ data) => controller.add(data);

  Future addStream(Stream stream) => controller.addStream(stream);

  Future close([int code, String reason]) {
    closeCode ??= closeCode;
    closeReason ??= closeReason;
    return controller.close();
  }

  String get extensions => null;

  String get protocol => null;

  int get readyState => throw UnsupportedError('unmocked');
  void addUtf8Text(List<int> bytes) => throw UnsupportedError('unmocked');

  Future get done => controller.done;

  Stream get stream => controller.stream;
}

void main() {
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
    SocketClient socketClient;
    final expectedMessage = r'{'
        r'"type":"start","id":"01020304-0506-4708-890a-0b0c0d0e0f10",'
        r'"payload":{"operationName":null,"variables":{},"query":"subscription {\n  \n}"}'
        r'}';
    setUp(overridePrint((log) {
      socketClient = SocketClient(
        'ws://echo.websocket.org',
        connect: EchoSocket.connect,
        protocols: null,
        config: SocketClientConfig(
          delayBetweenReconnectionAttempts: Duration(milliseconds: 1),
        ),
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
            SocketConnectionState.connecting,
            SocketConnectionState.connected,
          ],
        ),
      );
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
      socketClient.socket.stream
          .where((message) => message == expectedMessage)
          .first
          .then((_) {
        socketClient.socket.add(jsonEncode({
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

      socketClient.onConnectionLost();

      await socketClient.connectionState
          .where((state) => state == SocketConnectionState.connected)
          .first;

      // ignore: unawaited_futures
      socketClient.socket.stream
          .where((message) => message == expectedMessage)
          .first
          .then((_) {
        socketClient.socket.add(jsonEncode({
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

  group('SocketClient with const payload', () {
    SocketClient socketClient;
    const initPayload = {'token': 'mytoken'};

    setUp(overridePrint((log) {
      socketClient = SocketClient(
        'ws://echo.websocket.org',
        connect: EchoSocket.connect,
        config: SocketClientConfig(initialPayload: () => initPayload),
      );
    }));

    tearDown(overridePrint((log) async {
      await socketClient.dispose();
    }));

    test('connection', () async {
      await socketClient.connectionState
          .where((state) => state == SocketConnectionState.connected)
          .first;

      await expectLater(socketClient.socket.stream.map((s) {
        return jsonDecode(s)['payload'];
      }), emits(initPayload));
    });
  });

  group('SocketClient with future payload', () {
    SocketClient socketClient;
    const initPayload = {'token': 'mytoken'};

    setUp(overridePrint((log) {
      socketClient = SocketClient(
        'ws://echo.websocket.org',
        connect: EchoSocket.connect,
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

      await expectLater(socketClient.socket.stream.map((s) {
        return jsonDecode(s)['payload'];
      }), emits(initPayload));
    });
  });
}
