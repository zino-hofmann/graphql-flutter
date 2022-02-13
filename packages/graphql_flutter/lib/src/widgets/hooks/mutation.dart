import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:graphql_flutter/src/widgets/hooks/graphql_client.dart';
import 'package:graphql_flutter/src/widgets/query.dart';

typedef RunMutation<TParsed> = MultiSourceResult<TParsed> Function(
  Map<String, dynamic> variables, {
  Object? optimisticResult,
});

class MutationHookResult<TParsed> {
  final RunMutation<TParsed> runMutation;
  final QueryResult<TParsed> result;

  MutationHookResult({
    required this.runMutation,
    required this.result,
  });
}

MutationHookResult<TParsed> useMutation<TParsed>(
  MutationOptions<TParsed> options,
) {
  final watchOptions = useMemoized(
    () => options.asWatchQueryOptions(),
    [options],
  );
  final client = useGraphQLClient();
  final query = useWatchMutation<TParsed>(watchOptions);
  final snapshot = useStream(
    query.stream,
    initialData: query.latestResult ?? QueryResult.unexecuted,
  );
  final runMutation = useCallback((
    Map<String, dynamic> variables, {
    Object? optimisticResult,
  }) {
    final mutationCallbacks = MutationCallbackHandler(
      cache: client.cache,
      queryId: query.queryId,
      options: options,
    );
    return (query
          ..variables = variables
          ..optimisticResult = optimisticResult
          ..onData(mutationCallbacks.callbacks) // add callbacks to observable
        )
        .fetchResults();
  }, [client, query, options]);
  return MutationHookResult(
    runMutation: runMutation,
    result: snapshot.data!,
  );
}
