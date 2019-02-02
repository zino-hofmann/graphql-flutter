import 'package:graphql_flutter/src/link/fetch_result.dart';
import 'package:graphql_flutter/src/link/link.dart';
import 'package:graphql_flutter/src/link/operation.dart';
import 'package:graphql_flutter/src/socket_client.dart';
import 'package:graphql_flutter/src/websocket/messages.dart';

class WebSocketLink extends Link {
  final SocketClient socketClient;
  WebSocketLink(this.socketClient)
      : super(
          request: (
            Operation operation, [
            NextLink forward,
          ]) {
            return socketClient.subscribe(SubscriptionRequest(operation.operationName, operation.document, operation.variables)).map((result) {
              return FetchResult(data: result.data, errors: result.errors, context: operation.getContext(), extensions: operation.extensions);
            });
          },
        );
}
