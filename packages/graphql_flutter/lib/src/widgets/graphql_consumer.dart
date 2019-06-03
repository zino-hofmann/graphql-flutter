import 'package:flutter/widgets.dart';

import 'package:graphql/client.dart';

import 'package:graphql_flutter/src/widgets/graphql_provider.dart';

typedef GraphQLConsumerBuilder = Widget Function(GraphQLClient client);

class GraphQLConsumer extends StatelessWidget {
  const GraphQLConsumer({
    final Key key,
    @required this.builder,
  }) : super(key: key);

  final GraphQLConsumerBuilder builder;

  @override
  Widget build(BuildContext context) {
    /// Gets the client from the closest wrapping [GraphQLProvider].
    final GraphQLClient client = GraphQLProvider.of(context)?.value;
    assert(client != null);

    return builder(client);
  }
}
