import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:graphql/client.dart';
import 'package:graphql_flutter/src/widgets/hooks/graphql_client.dart';
import 'package:graphql_flutter/src/widgets/hooks/watch_query.dart';

// method to call from widget to fetchmore queries
typedef FetchMore<TParsed extends Object?> = Future<QueryResult<TParsed>>
    Function(FetchMoreOptions options);

typedef Refetch<TParsed extends Object?> = Future<QueryResult<TParsed>?>
    Function();

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
  final client = useGraphQLClient();
  return useQueryOnClient(client, options);
}

QueryHookResult<TParsed> useQueryOnClient<TParsed>(
  GraphQLClient client,
  QueryOptions<TParsed> options,
) {
  final watchQueryOptions = useMemoized(
    () => options.asWatchQueryOptions(),
    [options],
  );
  final query = useWatchQueryOnClient(client, watchQueryOptions);
  final snapshot = useStream(
    query.stream,
    initialData: query.latestResult,
  );

  useEffect(() {
    final cleanup = query.onData(
      QueryCallbackHandler(options: options).callbacks,
      removeAfterInvocation: false,
    );
    return cleanup;
  }, [options, query]);

  return QueryHookResult(
    result: snapshot.data!,
    refetch: query.refetch,
    fetchMore: query.fetchMore,
  );
}
