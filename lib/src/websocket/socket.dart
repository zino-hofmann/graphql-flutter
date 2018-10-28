import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../graphql_flutter.dart';

/// Wraps a standard web socket instance to marshal and un-marshal the server /
/// client payloads into dart object representation.
class GraphQLSocket {
  final StreamController<GraphQLSocketMessage> _subject =
      StreamController<GraphQLSocketMessage>.broadcast();

  final WebSocket _socket;

  GraphQLSocket(this._socket) {
    _socket.map((message) => json.decode(message)).listen((message) {
      final dynamic type = message['type'] ?? 'unknown';
      final dynamic payload = message['payload'] ?? {};
      final dynamic id = message['id'] ?? 'none';

      if (type == MessageTypes.GQL_CONNECTION_ACK) {
        _subject.add(ConnectionAck());
      } else if (type == MessageTypes.GQL_CONNECTION_ERROR) {
        _subject.add(ConnectionError(payload));
      } else if (type == MessageTypes.GQL_DATA) {
        final dynamic data = payload['data'] ?? null;
        final dynamic errors = payload['errors'] ?? null;
        _subject.add(SubscriptionData(id, data, errors));
      } else if (type == MessageTypes.GQL_ERROR) {
        _subject.add(SubscriptionError(id, payload));
      } else if (type == MessageTypes.GQL_COMPLETE) {
        _subject.add(SubscriptionComplete(id));
      } else {
        _subject.add(UnknownData(message));
      }
    });
  }

  void write(final GraphQLSocketMessage message) {
    _socket.add(json.encode(message, toEncodable: (m) => m.toJson()));
  }

  Stream<ConnectionAck> get connectionAck => _subject.stream
      .where((message) => message is ConnectionAck)
      .cast<ConnectionAck>();

  Stream<ConnectionError> get connectionError => _subject.stream
      .where((message) => message is ConnectionError)
      .cast<ConnectionError>();

  Stream<UnknownData> get unknownData => _subject.stream
      .where((message) => message is UnknownData)
      .cast<UnknownData>();

  Stream<SubscriptionData> get subscriptionData => _subject.stream
      .where((message) => message is SubscriptionData)
      .cast<SubscriptionData>();

  Stream<SubscriptionError> get subscriptionError => _subject.stream
      .where((message) => message is SubscriptionError)
      .cast<SubscriptionError>();

  Stream<SubscriptionComplete> get subscriptionComplete => _subject.stream
      .where((message) => message is SubscriptionComplete)
      .cast<SubscriptionComplete>();
}
