import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

GraphQLClient useGraphQLClient() {
  final context = useContext();
  return useValueListenable(GraphQLProvider.of(context));
}
