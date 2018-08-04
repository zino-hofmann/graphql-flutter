/// These messages represent the structures used for Client-server communication
/// in a GraphQL web-socket subscription. Each message is represented in a JSON
/// format where the data type is denoted by the `type` field.

/// A list of constants used for identifying message types
class MessageTypes {
  MessageTypes._();

  // client connections
  static const GQL_CONNECTION_INIT = 'connection_init';
  static const GQL_CONNECTION_TERMINATE = 'connection_terminate';

  // server connections
  static const GQL_CONNECTION_ACK = 'connection_ack';
  static const GQL_CONNECTION_ERROR = 'connection_error';

  // client operations
  static const GQL_START = 'start';
  static const GQL_STOP = 'stop';

  // server operations
  static const GQL_DATA = 'data';
  static const GQL_ERROR = 'error';
  static const GQL_COMPLETE = 'complete';

  // default tag for use in identifying issues
  static const GQL_UNKNOWN = 'unknown';
}

abstract class JsonSerializable {
  dynamic toJson();

  @override
  String toString() => toJson().toString();
}

/// Base type for representing a server-client subscription message.
abstract class GraphQLSocketMessage extends JsonSerializable {
  final String type;

  GraphQLSocketMessage(this.type);
}

/// After establishing a connection with the server, the client will
/// send this message to tell the server that it is ready to begin sending
/// new subscription queries.
class InitOperation extends GraphQLSocketMessage {
  InitOperation() : super(MessageTypes.GQL_CONNECTION_INIT);

  @override
  dynamic toJson() => {
        'type': type,
      };
}

/// Represent the payload used during a Start query operation.
/// The operationName should match one of the top level query definitions
/// defined in the query provided. Additional variables can be provided
/// and sent to the server for processing.
class SubscriptionRequest extends JsonSerializable {
  final String operationName;
  final String query;
  final dynamic variables;

  SubscriptionRequest(this.operationName, this.query, this.variables);

  @override
  dynamic toJson() => {
        'operationName': operationName,
        'query': query,
        'variables': variables,
      };
}

/// A message to tell the server to create a subscription. The contents of the
/// query will be defined by the payload request. The id provided will be used
/// to tag messages such that they can be identified for this subscription
/// instance. id values should be unique and not be re-used during the lifetime
/// of the server.
class StartOperation extends GraphQLSocketMessage {
  final String id;
  final SubscriptionRequest payload;

  StartOperation(this.id, this.payload) : super(MessageTypes.GQL_START);

  @override
  dynamic toJson() => {
        'type': type,
        'id': id,
        'payload': payload,
      };
}

/// Tell the server to stop sending subscription data for a particular
/// subscription instance. See StartOperation
class StopOperation extends GraphQLSocketMessage {
  final String id;

  StopOperation(this.id) : super(MessageTypes.GQL_STOP);

  @override
  dynamic toJson() => {
        'type': type,
        'id': id,
      };
}

/// The server will send this acknowledgment message after receiving the init
/// command from the client if the init was successful.
class ConnectionAck extends GraphQLSocketMessage {
  ConnectionAck() : super(MessageTypes.GQL_CONNECTION_ACK);

  @override
  dynamic toJson() => {
        'type': type,
      };
}

/// The server will send this error message after receiving the init command
/// from the client if the init was not successful.
class ConnectionError extends GraphQLSocketMessage {
  final dynamic payload;

  ConnectionError(this.payload) : super(MessageTypes.GQL_CONNECTION_ERROR);

  @override
  dynamic toJson() => {
        'type': type,
        'payload': payload,
      };
}

/// Data sent from the server to the client with subscription data or error
/// payload. The user should check the errors result before processing the
/// data value. These error are from the query resolvers.
class SubscriptionData extends GraphQLSocketMessage {
  final String id;
  final dynamic data;
  final dynamic errors;

  SubscriptionData(this.id, this.data, this.errors)
      : super(MessageTypes.GQL_DATA);

  @override
  dynamic toJson() => {
        'type': type,
        'data': data,
        'errors': errors,
      };
}

/// Errors sent from the server to the client if the subscription operation was
/// not successful, usually due to GraphQL validation errors.
class SubscriptionError extends GraphQLSocketMessage {
  final String id;
  final dynamic payload;

  SubscriptionError(this.id, this.payload) : super(MessageTypes.GQL_ERROR);

  @override
  dynamic toJson() => {
        'type': type,
        'id': id,
        'payload': payload,
      };
}

/// Server message to the client to indicate that no more data will be sent
/// for a particular subscription instance.
class SubscriptionComplete extends GraphQLSocketMessage {
  final String id;

  SubscriptionComplete(this.id) : super(MessageTypes.GQL_COMPLETE);

  @override
  dynamic toJson() => {
        'type': type,
        'id': id,
      };
}

/// Not expected to be created. Indicates there are problems parsing the server
/// response, or that new unsupported types have been added to the subscription
/// implementation.
class UnknownData extends GraphQLSocketMessage {
  final dynamic payload;

  UnknownData(this.payload) : super(MessageTypes.GQL_UNKNOWN);

  @override
  dynamic toJson() => {
        'type': type,
        'payload': payload,
      };
}
