import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:graphql_flutter/src/widgets/hooks/watch_query.dart';

// method to call from widget to fetchmore queries
typedef FetchMore<TParsed> = Future<QueryResult<TParsed>> Function(
    FetchMoreOptions options);

typedef Refetch<TParsed> = Future<QueryResult<TParsed>?> Function();

class QueryHookResult<TParsed> {
  final QueryResult<TParsed> result;
  final Refetch<TParsed> refetch;
  final FetchMore<TParsed> fetchMore;

  QueryHookResult({
    required this.result,
    required this.refetch,
    required this.fetchMore,
  });
}

QueryHookResult<TParsed> useQuery<TParsed>(QueryOptions<TParsed> options) {
  final watchQueryOptions = useMemoized(
    () => options.asWatchQueryOptions(),
    [options],
  );
  final query = useWatchQuery(watchQueryOptions);
  final snapshot = useStream(
    query.stream,
    initialData: query.latestResult,
  );
  return QueryHookResult(
    result: snapshot.data!,
    refetch: query.refetch,
    fetchMore: query.fetchMore,
  );
}
