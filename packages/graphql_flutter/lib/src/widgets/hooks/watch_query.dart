import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:graphql/client.dart';
import 'package:graphql_flutter/src/widgets/hooks/graphql_client.dart';

class _WatchQueryHook<TParsed> extends Hook<ObservableQuery<TParsed>> {
  final GraphQLClient client;
  final WatchQueryOptions<TParsed> options;

  _WatchQueryHook({
    required this.options,
    required this.client,
  });

  @override
  HookState<ObservableQuery<TParsed>, Hook<ObservableQuery<TParsed>>>
      createState() {
    return _WatchQueryHookState();
  }
}

class _WatchQueryHookState<TParsed>
    extends HookState<ObservableQuery<TParsed>, _WatchQueryHook<TParsed>> {
  late ObservableQuery<TParsed> _observableQuery;

  @override
  initHook() {
    super.initHook();
    _connect();
  }

  @override
  dispose() {
    _close();
    super.dispose();
  }

  void _connect() {
    _observableQuery = hook.client.queryManager.watchQuery(hook.options);
  }

  void _close() {
    _observableQuery.close();
  }

  void _reconnect() {
    _close();
    _connect();
  }

  @override
  didUpdateHook(oldHook) {
    super.didUpdateHook(oldHook);
    if (oldHook.client == hook.client && oldHook.options == hook.options) {
      return;
    }
    _reconnect();
  }

  ObservableQuery<TParsed> build(BuildContext context) {
    return _observableQuery;
  }
}

ObservableQuery<TParsed> useWatchQuery<TParsed>(
  WatchQueryOptions<TParsed> options,
) {
  final client = useGraphQLClient();
  return useWatchQueryOnClient(client, options);
}

ObservableQuery<TParsed> useWatchQueryOnClient<TParsed>(
  GraphQLClient client,
  WatchQueryOptions<TParsed> options,
) {
  final overwrittenOptions = useMemoized(() {
    final policies =
        client.defaultPolicies.watchQuery.withOverrides(options.policies);
    return options.copyWithPolicies(policies);
  }, [options]);

  return use(_WatchQueryHook(
    options: overwrittenOptions,
    client: client,
  ));
}

ObservableQuery<TParsed> useWatchMutation<TParsed>(
  WatchQueryOptions<TParsed> options,
) {
  final client = useGraphQLClient();
  return useWatchMutationOnClient(client, options);
}

ObservableQuery<TParsed> useWatchMutationOnClient<TParsed>(
  GraphQLClient client,
  WatchQueryOptions<TParsed> options,
) {
  final overwrittenOptions = useMemoized(() {
    final policies =
        client.defaultPolicies.watchMutation.withOverrides(options.policies);
    return options.copyWithPolicies(policies);
  }, [options]);
  return use(
    _WatchQueryHook(
      options: overwrittenOptions,
      client: client,
    ),
  );
}
