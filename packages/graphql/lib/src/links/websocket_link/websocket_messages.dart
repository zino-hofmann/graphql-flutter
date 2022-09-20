// Adapted to `gql` by @iscriptology

import "dart:convert";

/// These messages represent the structures used for Client-server communication
/// in a GraphQL web-socket subscription. Each message is represented in a JSON
/// format where the data type is denoted by the `type` field.

/// A list of constants used for identifying message types
class MessageTypes {
  MessageTypes._();

  // client connections
  static const String connectionInit = "connection_init";
  static const String connectionTerminate = "connection_terminate";

  // server connections
  static const String connectionAck = "connection_ack";
  static const String connectionError = "connection_error";
  static const String connectionKeepAlive = "ka";

  // client operations
  static const String subscribe = "subscribe";
  static const String start = "start";
  static const String stop = "stop";

  static const String ping = "ping";
  static const String pong = "pong";

  // server operations
  static const String data = "data";
  static const String next = "next";
  static const String error = "error";
  static const String complete = "complete";

  // default tag for use in identifying issues
  static const String unknown = "unknown";
}

abstract class JsonSerializable {
  Map<String, dynamic> toJson();

  @override
  String toString() => toJson().toString();
}

/// Base type for representing a server-client subscription message.
abstract class GraphQLSocketMessage extends JsonSerializable {
  GraphQLSocketMessage(this.type);

  final String type;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{"type": type};

  static GraphQLSocketMessage parse(dynamic message) {
    final Map<String, dynamic> map =
        json.decode(message as String) as Map<String, dynamic>;
    final String type = (map['type'] ?? 'unknown') as String;
    final payload =
        (map['payload'] ?? <String, dynamic>{}) as Map<String, dynamic>;
    final String id = (map['id'] ?? 'none') as String;

    switch (type) {
      // for completeness
      case MessageTypes.connectionInit:
        return InitOperation(payload);
      case MessageTypes.connectionTerminate:
        return TerminateOperation();

      case MessageTypes.connectionAck:
        return ConnectionAck();
      case MessageTypes.connectionError:
        return ConnectionError(payload);
      case MessageTypes.connectionKeepAlive:
        return ConnectionKeepAlive();

      // for completeness
      case MessageTypes.subscribe:
        return SubscribeOperation(id, payload);
      case MessageTypes.start:
        return StartOperation(id, payload);
      case MessageTypes.stop:
        return StopOperation(id);
      case MessageTypes.ping:
        return PingMessage(payload);
      case MessageTypes.pong:
        return PongMessage(payload);

      case MessageTypes.data:
        return SubscriptionData(id, payload['data'], payload['errors']);
      case MessageTypes.next:
        return SubscriptionNext(id, payload['data'], payload['errors']);
      case MessageTypes.error:
        return SubscriptionError(id, payload);
      case MessageTypes.complete:
        return SubscriptionComplete(id);
      default:
        return UnknownData(map);
    }
  }
}

/// After establishing a connection with the server, the client will
/// send this message to tell the server that it is ready to begin sending
/// new subscription queries.
class InitOperation extends GraphQLSocketMessage {
  InitOperation(this.payload) : super(MessageTypes.connectionInit);

  final dynamic payload;

  @override
  toJson() => {
        "type": type,
        if (payload != null) "payload": payload,
      };
}

/// The client sends this message to terminate the connection.
class TerminateOperation extends GraphQLSocketMessage {
  TerminateOperation() : super(MessageTypes.connectionTerminate);
}

/// Represent the payload used during a Start query operation.
/// The operationName should match one of the top level query definitions
/// defined in the query provided. Additional variables can be provided
/// and sent to the server for processing.
class QueryPayload extends JsonSerializable {
  QueryPayload({
    this.operationName,
    required this.query,
    required this.variables,
  });

  final String? operationName;
  final String query;
  final Map<String, dynamic> variables;

  @override
  toJson() => {
        "operationName": operationName,
        "query": query,
        "variables": variables,
      };
}

class SubscribeOperation extends GraphQLSocketMessage {
  SubscribeOperation(this.id, this.payload) : super(MessageTypes.subscribe);

  final String id;

  final Map<String, dynamic> payload;

  @override
  toJson() => {
        "type": type,
        "id": id,
        "payload": payload,
      };
}

class PingMessage extends GraphQLSocketMessage {
  PingMessage([this.payload = const <String, dynamic>{}])
      : super(MessageTypes.ping);

  final Map<String, dynamic> payload;

  @override
  toJson() => {
        "type": type,
        "payload": payload,
      };
}

class PongMessage extends GraphQLSocketMessage {
  PongMessage([this.payload]) : super(MessageTypes.pong);

  final Map<String, dynamic>? payload;

  @override
  toJson() => {
        "type": type,
        "payload": payload,
      };
}

/// A message to tell the server to create a subscription. The contents of the
/// query will be defined by the payload request. The id provided will be used
/// to tag messages such that they can be identified for this subscription
/// instance. id values should be unique and not be re-used during the lifetime
/// of the server.
class StartOperation extends GraphQLSocketMessage {
  StartOperation(this.id, this.payload) : super(MessageTypes.start);

  final String id;
//  final QueryPayload payload;
  final Map<String, dynamic> payload;

  @override
  toJson() => {
        "type": type,
        "id": id,
        "payload": payload,
      };
}

/// Tell the server to stop sending subscription data for a particular
/// subscription instance. See [StartOperation].
class StopOperation extends GraphQLSocketMessage {
  StopOperation(this.id) : super(MessageTypes.stop);

  final String id;

  @override
  toJson() => {"type": type, "id": id};
}

/// The server will send this acknowledgment message after receiving the init
/// command from the client if the init was successful.
class ConnectionAck extends GraphQLSocketMessage {
  ConnectionAck() : super(MessageTypes.connectionAck);
}

/// The server will send this error message after receiving the init command
/// from the client if the init was not successful.
class ConnectionError extends GraphQLSocketMessage {
  ConnectionError(this.payload) : super(MessageTypes.connectionError);

  final dynamic payload;

  @override
  toJson() => {"type": type, "payload": payload};
}

/// The server will send this message to keep the connection alive
class ConnectionKeepAlive extends GraphQLSocketMessage {
  ConnectionKeepAlive() : super(MessageTypes.connectionKeepAlive);
}

/// Data sent from the server to the client with subscription data or error
/// payload. The user should check the errors result before processing the
/// data value. These error are from the query resolvers.
class SubscriptionData extends GraphQLSocketMessage {
  SubscriptionData(this.id, this.data, this.errors) : super(MessageTypes.data);

  final String id;
  final dynamic data;
  final dynamic errors;

  @override
  toJson() => {
        "type": type,
        "data": data,
        "errors": errors,
      };

  @override
  int get hashCode => toJson().hashCode;

  @override
  bool operator ==(dynamic other) =>
      other is SubscriptionData && jsonEncode(other) == jsonEncode(this);
}

class SubscriptionNext extends GraphQLSocketMessage {
  SubscriptionNext(this.id, this.data, this.errors) : super(MessageTypes.next);

  final String id;
  final dynamic data;
  final dynamic errors;

  @override
  toJson() => {
        "type": type,
        "data": data,
        "errors": errors,
      };

  @override
  int get hashCode => toJson().hashCode;

  @override
  bool operator ==(dynamic other) =>
      other is SubscriptionNext && jsonEncode(other) == jsonEncode(this);
}

/// Errors sent from the server to the client if the subscription operation was
/// not successful, usually due to GraphQL validation errors.
class SubscriptionError extends GraphQLSocketMessage {
  SubscriptionError(this.id, this.payload) : super(MessageTypes.error);

  final String id;
  final dynamic payload;

  @override
  toJson() => {
        "type": type,
        "id": id,
        "payload": payload,
      };
}

/// Server message to the client to indicate that no more data will be sent
/// for a particular subscription instance.
class SubscriptionComplete extends GraphQLSocketMessage {
  SubscriptionComplete(this.id) : super(MessageTypes.complete);

  final String id;

  @override
  toJson() => {"type": type, "id": id};
}

/// Not expected to be created. Indicates there are problems parsing the server
/// response, or that new unsupported types have been added to the subscription
/// implementation.
class UnknownData extends GraphQLSocketMessage {
  UnknownData(this.payload) : super(MessageTypes.unknown);

  final dynamic payload;

  @override
  toJson() => {"type": type, "payload": payload};
}
