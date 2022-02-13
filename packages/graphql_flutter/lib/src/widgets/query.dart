import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:graphql_flutter/graphql_flutter.dart';
export 'package:graphql_flutter/graphql_flutter.dart';

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
    final result = useQuery(options);
    return builder(
      result.result,
      fetchMore: result.fetchMore,
      refetch: result.refetch,
    );
  }
}
