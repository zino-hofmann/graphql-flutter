import 'package:flutter/widgets.dart';

import 'package:graphql_flutter/src/client.dart';
import 'package:graphql_flutter/src/widgets/graphql_provider.dart';

typedef Widget GraphqlConsumerBuilder(Client client);

class GraphqlConsumer extends StatelessWidget {
  GraphqlConsumer({
    final Key key,
    @required this.builder,
  }) : super(key: key);

  final GraphqlConsumerBuilder builder;

  Widget build(BuildContext context) {
    /// Gets the client from the closest wrapping [GraphqlProvider].
    Client client = GraphqlProvider.of(context).value;
    assert(client != null);

    return builder(client);
  }
}
