/// Client Provider is a utils class that contains in a single place
/// all the client used to ran the integration testing with all the
/// servers.
///
/// The test supported in this class for the moment are:
/// - GraphQl Client Chat: https://github.com/vincenzopalazzo/keep-safe-graphql
///
/// author: https://github.com/vincenzopalazzo

/// ClientProvider is a singleton implementation that contains
/// all the client supported to implement the integration testing.
import 'package:graphql_flutter/graphql_flutter.dart';

class ClientProvider {
  static ClientProvider? _instance;

  GraphQLClient? _chatApp;

  ClientProvider._internal();

  factory ClientProvider() {
    _instance ??= ClientProvider._internal();
    return _instance!;
  }

  /// Init the client regarding the chat app server
  /// crete only a single instance of it.
  GraphQLClient chatAppClient(
      {GraphQLCache? cache, bool forceRecreation = false}) {
    if (_chatApp == null || forceRecreation) {
      final HttpLink httpLink = HttpLink(
        'https://api.chat.graphql-flutter.dev/graphql',
        defaultHeaders: {
          "Accept": "application/json",
          "Access-Control_Allow_Origin": "*",
        },
      );
      var wsLink = WebSocketLink(
        'ws://api.chat.graphql-flutter.dev/graphql',
        config: const SocketClientConfig(
          inactivityTimeout: Duration(seconds: 40),
        ),
        subProtocol: GraphQLProtocol.graphqlTransportWs,
      );
      final Link link = httpLink.split(
        (request) => request.isSubscription,
        wsLink,
        httpLink,
      );
      if (!forceRecreation) {
        _chatApp = GraphQLClient(link: link, cache: cache ?? GraphQLCache());
      } else {
        return GraphQLClient(link: link, cache: cache ?? GraphQLCache());
      }
    }
    return _chatApp!;
  }
}
