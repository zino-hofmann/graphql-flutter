import 'dart:convert';

import 'package:gql/language.dart';
import 'package:graphql/src/link/operation.dart';

/// These messages represent the structures used for Client-server communication
/// in a GraphQL web-socket subscription. Each message is represented in a JSON
/// format where the data type is denoted by the `type` field.

/// A list of constants used for identifying message types
class MessageTypes {
  MessageTypes._();

  // client connections
  static const String GQL_CONNECTION_INIT = 'connection_init';
  static const String GQL_CONNECTION_TERMINATE = 'connection_terminate';

  // server connections
  static const String GQL_CONNECTION_ACK = 'connection_ack';
  static const String GQL_CONNECTION_ERROR = 'connection_error';
  static const String GQL_CONNECTION_KEEP_ALIVE = 'ka';

  // client operations
  static const String GQL_START = 'start';
  static const String GQL_STOP = 'stop';

  // server operations
  static const String GQL_DATA = 'data';
  static const String GQL_ERROR = 'error';
  static const String GQL_COMPLETE = 'complete';

  // default tag for use in identifying issues
  static const String GQL_UNKNOWN = 'unknown';
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
}

/// After establishing a connection with the server, the client will
/// send this message to tell the server that it is ready to begin sending
/// new subscription queries.
class InitOperation extends GraphQLSocketMessage {
  InitOperation(this.payload) : super(MessageTypes.GQL_CONNECTION_INIT);

  final dynamic payload;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> jsonMap = <String, dynamic>{};
    jsonMap['type'] = type;

    if (payload != null) {
      jsonMap['payload'] = payload;
    }

    return jsonMap;
  }
}

/// Represent the payload used during a Start query operation.
/// The operationName should match one of the top level query definitions
/// defined in the query provided. Additional variables can be provided
/// and sent to the server for processing.
class SubscriptionRequest extends JsonSerializable {
  SubscriptionRequest(this.operation);
  final Operation operation;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'operationName': operation.operationName,
        'query': printNode(operation.documentNode),
        'variables': operation.variables,
      };
}

/// A message to tell the server to create a subscription. The contents of the
/// query will be defined by the payload request. The id provided will be used
/// to tag messages such that they can be identified for this subscription
/// instance. id values should be unique and not be re-used during the lifetime
/// of the server.
class StartOperation extends GraphQLSocketMessage {
  StartOperation(this.id, this.payload) : super(MessageTypes.GQL_START);

  final String id;
  final SubscriptionRequest payload;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'id': id,
        'payload': payload,
      };
}

/// Tell the server to stop sending subscription data for a particular
/// subscription instance. See [StartOperation].
class StopOperation extends GraphQLSocketMessage {
  StopOperation(this.id) : super(MessageTypes.GQL_STOP);

  final String id;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'id': id,
      };
}

/// The server will send this acknowledgment message after receiving the init
/// command from the client if the init was successful.
class ConnectionAck extends GraphQLSocketMessage {
  ConnectionAck() : super(MessageTypes.GQL_CONNECTION_ACK);

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
      };
}

/// The server will send this error message after receiving the init command
/// from the client if the init was not successful.
class ConnectionError extends GraphQLSocketMessage {
  ConnectionError(this.payload) : super(MessageTypes.GQL_CONNECTION_ERROR);

  final dynamic payload;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'payload': payload,
      };
}

/// The server will send this message to keep the connection alive
class ConnectionKeepAlive extends GraphQLSocketMessage {
  ConnectionKeepAlive() : super(MessageTypes.GQL_CONNECTION_KEEP_ALIVE);

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
      };
}

/// Data sent from the server to the client with subscription data or error
/// payload. The user should check the errors result before processing the
/// data value. These error are from the query resolvers.
class SubscriptionData extends GraphQLSocketMessage {
  SubscriptionData(this.id, this.data, this.errors)
      : super(MessageTypes.GQL_DATA);

  final String id;
  final dynamic data;
  final dynamic errors;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'data': data,
        'errors': errors,
      };

  @override
  int get hashCode => toJson().hashCode;

  @override
  bool operator ==(dynamic other) =>
      other is SubscriptionData && jsonEncode(other) == jsonEncode(this);
}

/// Errors sent from the server to the client if the subscription operation was
/// not successful, usually due to GraphQL validation errors.
class SubscriptionError extends GraphQLSocketMessage {
  SubscriptionError(this.id, this.payload) : super(MessageTypes.GQL_ERROR);

  final String id;
  final dynamic payload;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'id': id,
        'payload': payload,
      };
}

/// Server message to the client to indicate that no more data will be sent
/// for a particular subscription instance.
class SubscriptionComplete extends GraphQLSocketMessage {
  SubscriptionComplete(this.id) : super(MessageTypes.GQL_COMPLETE);

  final String id;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'id': id,
      };
}

/// Not expected to be created. Indicates there are problems parsing the server
/// response, or that new unsupported types have been added to the subscription
/// implementation.
class UnknownData extends GraphQLSocketMessage {
  UnknownData(this.payload) : super(MessageTypes.GQL_UNKNOWN);

  final dynamic payload;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'payload': payload,
      };
}
