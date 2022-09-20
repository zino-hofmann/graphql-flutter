import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:graphql/client.dart';
import 'package:graphql_flutter/src/widgets/hooks/graphql_client.dart';
import 'package:graphql_flutter/src/widgets/hooks/query.dart';

typedef QueryBuilder<TParsed> = Widget Function(
  QueryResult<TParsed> result, {
  Refetch<TParsed>? refetch,
  FetchMore<TParsed>? fetchMore,
});

/// Builds a [Query] widget based on the a given set of [QueryOptions]
/// that streams [QueryResult]s into the [QueryBuilder].
class Query<TParsed> extends HookWidget {
  const Query({
    final Key? key,
    required this.options,
    required this.builder,
  }) : super(key: key);

  final QueryOptions<TParsed> options;
  final QueryBuilder<TParsed> builder;

  @override
  Widget build(BuildContext context) {
    final client = useGraphQLClient();
    return QueryOnClient(
      options: options,
      builder: builder,
      client: client,
    );
  }
}

/// Builds a [QueryOnClient] widget based on the a given set of [QueryOptions]
/// that streams [QueryResult]s into the [QueryBuilder].
class QueryOnClient<TParsed> extends HookWidget {
  const QueryOnClient({
    final Key? key,
    required this.options,
    required this.builder,
    required this.client,
  }) : super(key: key);

  final GraphQLClient client;
  final QueryOptions<TParsed> options;
  final QueryBuilder<TParsed> builder;

  @override
  Widget build(BuildContext context) {
    final result = useQueryOnClient(client, options);
    return builder(
      result.result,
      fetchMore: result.fetchMore,
      refetch: result.refetch,
    );
  }
}
