import 'dart:async';

import 'package:async/async.dart';
import 'package:rxdart/subjects.dart';
import 'package:stream_channel/src/stream_channel_transformer.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:gql/language.dart';
import 'package:graphql/client.dart';
import 'package:graphql/src/links/websocket_link/websocket_client.dart';
import 'package:graphql/src/links/websocket_link/websocket_messages.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import './helpers.dart';

class EchoSink extends DelegatingStreamSink implements WebSocketSink {
  final StreamSink sink;

  EchoSink(StreamSink sink)
      : this.sink = sink,
        super(sink);

  @override
  Future close([int? closeCode, String? closeReason]) {
    return super.close();
  }
}

class EchoSocket implements WebSocketChannel {
  final StreamController controller;

  EchoSocket.connect(this.controller) : sink = EchoSink(controller.sink);

  @override
  Stream get stream => controller.stream;

  @override
  final WebSocketSink sink;

  @override
  StreamChannel<S> cast<S>() => throw UnimplementedError();

  @override
  StreamChannel changeSink(
    StreamSink Function(StreamSink p1) change,
  ) =>
      throw UnimplementedError();

  @override
  StreamChannel changeStream(
    Stream Function(Stream p1) change,
  ) =>
      throw UnimplementedError();

  @override
  int get closeCode => throw UnimplementedError();

  @override
  String get closeReason => throw UnimplementedError();

  @override
  void pipe(StreamChannel other) {}

  @override
  String get protocol => throw UnimplementedError();

  @override
  StreamChannel<S> transform<S>(
    StreamChannelTransformer<S, dynamic> transformer,
  ) =>
      throw UnimplementedError();

  @override
  StreamChannel transformSink(
    StreamSinkTransformer transformer,
  ) =>
      throw UnimplementedError();

  @override
  StreamChannel transformStream(
    StreamTransformer transformer,
  ) =>
      throw UnimplementedError();
}

SocketClient getTestClient([StreamController? controller]) => SocketClient(
      'ws://echo.websocket.org',
      connect: (_, __) => EchoSocket.connect(controller ?? BehaviorSubject()),
      config: SocketClientConfig(
        delayBetweenReconnectionAttempts: Duration(milliseconds: 1),
      ),
      randomBytesForUuid: Uint8List.fromList(
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
      ),
    );

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
    late SocketClient socketClient;
    StreamController controller;
    final expectedMessage = r'{'
        r'"type":"start","id":"01020304-0506-4708-890a-0b0c0d0e0f10",'
        r'"payload":{"operationName":null,"variables":{},"query":"subscription {\n  \n}"}'
        r'}';
    setUp(overridePrint((log) {
      controller = StreamController(sync: true);
      socketClient = getTestClient(controller);
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

      socketClient.onConnectionLost();

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
  }, tags: "integration");

  group('SocketClient with const payload', () {
    late SocketClient socketClient;
    const initPayload = {'token': 'mytoken'};

    setUp(overridePrint((log) {
      socketClient = SocketClient(
        'ws://echo.websocket.org',
        connect: (_, __) => EchoSocket.connect(BehaviorSubject()),
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
        'ws://echo.websocket.org',
        connect: (_, __) => EchoSocket.connect(BehaviorSubject()),
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
  });
}
