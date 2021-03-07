import 'dart:async';
import 'package:graphql/client.dart';
import 'package:meta/meta.dart';

import 'package:graphql/src/core/query_manager.dart';
import 'package:graphql/src/core/query_options.dart';
import 'package:graphql/src/core/fetch_more.dart';
import 'package:graphql/src/core/query_result.dart';
import 'package:graphql/src/core/policies.dart';
import 'package:graphql/src/scheduler/scheduler.dart';

/// Side effect to register for execution when data is received
typedef OnData = FutureOr<void> Function(QueryResult? result);

/// Lifecycle states for [ObservableQuery.lifecycle]
enum QueryLifecycle {
  /// No results have been requested or fetched
  unexecuted,

  /// Results are being fetched, and will be side-effect free
  pending,

  /// Polling for results periodically
  polling,

  /// Was polling but [ObservableQuery.stopPolling()] was called
  pollingStopped,

  /// Results are being fetched, and will trigger
  /// the callbacks registered with [ObservableQuery.onData]
  sideEffectsPending,

  /// Pending side effects are preventing [ObservableQuery.close],
  /// and the [ObservableQuery] will be discarded after fetch completes
  /// and side effects are resolved.
  sideEffectsBlocking,

  /// The operation was executed and is not [polling]
  completed,

  /// [ObservableQuery.close] was called and all activity
  /// from this [ObservableQuery] has ceased.
  closed
}

/// An Observable/Stream-based API for both queries and mutations.
///
/// Returned from [GraphQLClient.watchQuery] for use in reactive programming,
/// for instance in `graphql_flutter` widgets.
/// It is modelled closely after [Apollo's ObservableQuery][apollo_oq]
///
/// [ObservableQuery]'s core api/usage is to [fetchResults], then listen to the [stream].
/// [fetchResults] will be called on instantiation if [options.eagerlyFetchResults] is set,
/// which in turn defaults to [options.fetchResults].
///
/// Beyond that, [ObservableQuery] is a bit of a kitchen sink:
/// * There are [refetch] and [fetchMore] methods for fetching more results
/// * An [onData] method for registering callbacks (namely for mutations)
/// * [lifecycle] for tracking  polling, side effect, an inflight execution state
/// * [latestResult] – the most recent result from this operation
///
/// And a handful of internally leveraged methods.
///
/// [apollo_oq]: https://www.apollographql.com/docs/react/v3.0-beta/api/core/ObservableQuery/
class ObservableQuery {
  ObservableQuery({
    required this.queryManager,
    required this.options,
  }) : queryId = queryManager.generateQueryId().toString() {
    if (options.eagerlyFetchResults) {
      _latestWasEagerlyFetched = true;
      fetchResults();
    }
    controller = StreamController<QueryResult>.broadcast(
      onListen: onListen,
    );
  }

  // set to true when eagerly fetched to prevent back-to-back queries
  bool _latestWasEagerlyFetched = false;

  /// The identity of this query within the [QueryManager]
  final String queryId;

  @protected
  final QueryManager queryManager;

  @protected
  QueryScheduler? get scheduler => queryManager.scheduler;

  /// callbacks registered with [onData]
  List<OnData> _onDataCallbacks = [];

  /// call [queryManager.maybeRebroadcastQueries] after all other [_onDataCallbacks]
  ///
  /// Automatically appended as an [OnData]
  FutureOr<void> _maybeRebroadcast(QueryResult? result) =>
      queryManager.maybeRebroadcastQueries(exclude: this);

  /// The most recently seen result from this operation's stream
  QueryResult? latestResult;

  QueryLifecycle lifecycle = QueryLifecycle.unexecuted;

  WatchQueryOptions options;

  late StreamController<QueryResult> controller;

  Stream<QueryResult> get stream => controller.stream;
  bool get isCurrentlyPolling => lifecycle == QueryLifecycle.polling;

  bool get isRefetchSafe {
    if (!options.isQuery) {
      return false;
    }
    switch (lifecycle) {
      case QueryLifecycle.completed:
      case QueryLifecycle.polling:
      case QueryLifecycle.pollingStopped:
        return true;

      case QueryLifecycle.pending:
      case QueryLifecycle.closed:
      case QueryLifecycle.unexecuted:
      case QueryLifecycle.sideEffectsPending:
      case QueryLifecycle.sideEffectsBlocking:
        return false;
    }
  }

  /// Attempts to refetch _on the network_, throwing error if not refetch safe
  ///
  /// **NOTE:** overrides any present non-network-only [FetchPolicy],
  /// as refetching from the `cache` does not make sense.
  Future<QueryResult?> refetch() {
    if (isRefetchSafe) {
      addResult(QueryResult.loading(data: latestResult?.data));
      return queryManager.refetchQuery(queryId);
    }
    throw Exception('Query is not refetch safe');
  }

  /// Whether it is safe to rebroadcast results due to cache
  /// changes based on policies and [lifecycle].
  ///
  /// Called internally by the [QueryManager]
  bool get isRebroadcastSafe {
    if (!options.policies.allowsRebroadcasting) {
      return false;
    }
    switch (lifecycle) {
      case QueryLifecycle.pending:
      case QueryLifecycle.completed:
      case QueryLifecycle.polling:
      case QueryLifecycle.pollingStopped:
        return true;

      case QueryLifecycle.unexecuted: // this might be ok
      case QueryLifecycle.closed:
      case QueryLifecycle.sideEffectsPending:
      case QueryLifecycle.sideEffectsBlocking:
        return false;
    }
  }

  void onListen() {
    if (_latestWasEagerlyFetched) {
      _latestWasEagerlyFetched = false;

      // eager results are resolved synchronously,
      // so we have to add them manually now that
      // the stream is available
      if (!controller.isClosed && latestResult != null) {
        controller.add(latestResult!);
      }
      return;
    }
    if (options.fetchResults) {
      fetchResults();
    }
  }

  /// Fetch results based on [options.fetchPolicy]
  ///
  /// Will [startPolling] if [options.pollInterval] is set
  MultiSourceResult fetchResults() {
    final MultiSourceResult allResults =
        queryManager.fetchQueryAsMultiSourceResult(queryId, options);
    latestResult ??= allResults.eagerResult;

    if (allResults.networkResult == null) {
      // This path is only possible for cacheFirst and cacheOnly fetch policies.
      lifecycle = QueryLifecycle.completed;
    } else {
      // if onData callbacks have been registered,
      // they are waited on by default
      lifecycle = _onDataCallbacks.isNotEmpty
          ? QueryLifecycle.sideEffectsPending
          : QueryLifecycle.pending;
    }

    if (options.pollInterval != null && options.pollInterval! > Duration.zero) {
      startPolling(options.pollInterval);
    }

    return allResults;
  }

  /// fetch more results and then merge them with the [latestResult]
  /// according to [FetchMoreOptions.updateQuery].
  ///
  /// The results will then be added to to stream for listeners to react to,
  /// such as for triggering `grahphql_flutter` widget rebuilds
  ///
  /// **NOTE**: with the addition of strict data structure checking in v4,
  /// it is easy to make mistakes in writing [updateQuery].
  ///
  /// To mitigate this, [FetchMoreOptions.partial] has been provided.
  Future<QueryResult> fetchMore(FetchMoreOptions fetchMoreOptions) async {
    addResult(QueryResult.loading(data: latestResult?.data));

    return fetchMoreImplementation(
      fetchMoreOptions,
      originalOptions: options,
      queryManager: queryManager,
      previousResult: latestResult!,
      queryId: queryId,
    );
  }

  /// Add a [result] to the [stream] unless it was created
  /// before [lasestResult].
  ///
  /// Copies the [QueryResult.source] from the [latestResult]
  /// if it is set to `null`.
  ///
  /// Called internally by the [QueryManager]
  void addResult(QueryResult result, {bool fromRebroadcast = false}) {
    // don't overwrite results due to some async/optimism issue
    if (latestResult != null &&
        latestResult!.timestamp.isAfter(result.timestamp)) {
      return;
    }

    if (options.carryForwardDataOnException && result.hasException) {
      result.data ??= latestResult?.data;
    }

    if (lifecycle == QueryLifecycle.pending && result.isConcrete) {
      lifecycle = QueryLifecycle.completed;
    }

    latestResult = result;

    // TODO should callbacks be applied before or after streaming
    if (!controller.isClosed) {
      controller.add(result);
    }

    if (result.isNotLoading) {
      _applyCallbacks(result, fromRebroadcast: fromRebroadcast);
    }
  }

  // most mutation behavior happens here
  /// Register [callbacks] to trigger when [stream] has new results
  /// where [QueryResult.isNotLoading]
  ///
  /// Will deregister [callbacks] after calling them on the first
  /// result that [QueryResult.isConcrete],
  /// handling the resolution of [lifecycle] from
  /// [QueryLifecycle.sideEffectsBlocking] to [QueryLifecycle.completed]
  /// as appropriate
  void onData(Iterable<OnData> callbacks) => _onDataCallbacks.addAll(callbacks);

  /// Applies [onData] callbacks at the end of [addResult]
  ///
  /// [fromRebroadcast] is used to avoid the super-edge case of infinite rebroadcasts
  /// (not sure if it's even possible)
  void _applyCallbacks(
    QueryResult? result, {
    bool fromRebroadcast = false,
  }) async {
    final callbacks = [
      ..._onDataCallbacks,
      if (!fromRebroadcast) _maybeRebroadcast
    ];
    for (final callback in callbacks) {
      await callback(result);
    }

    if (lifecycle == QueryLifecycle.closed) {
      // .close(force: true) was called
      return;
    }

    if (result!.isConcrete) {
      // avoid removing new callbacks
      _onDataCallbacks.removeWhere((cb) => callbacks.contains(cb));

      // if there are new callbacks, there is maybe another inflight mutation
      if (_onDataCallbacks.isEmpty) {
        if (lifecycle == QueryLifecycle.sideEffectsBlocking) {
          lifecycle = QueryLifecycle.completed;
          close();
        }
        // the mutation has been completed, but disposal has not been requested
        if (lifecycle == QueryLifecycle.sideEffectsPending) {
          lifecycle = QueryLifecycle.completed;
        }
      }
    }
  }

  /// Poll the server periodically for results.
  ///
  /// Will be called by [fetchResults] automatically if [options.pollInterval] is set
  void startPolling(Duration? pollInterval) {
    if (options.fetchPolicy == FetchPolicy.cacheFirst ||
        options.fetchPolicy == FetchPolicy.cacheOnly) {
      throw Exception(
        'Queries that specify the cacheFirst and cacheOnly fetch policies cannot also be polling queries.',
      );
    }

    if (isCurrentlyPolling) {
      scheduler!.stopPollingQuery(queryId);
    }

    options.pollInterval = pollInterval;
    lifecycle = QueryLifecycle.polling;
    scheduler!.startPollingQuery(options, queryId);
  }

  void stopPolling() {
    if (isCurrentlyPolling) {
      scheduler!.stopPollingQuery(queryId);
      options.pollInterval = null;
      lifecycle = QueryLifecycle.pollingStopped;
    }
  }

  set variables(Map<String, dynamic> variables) =>
      options.variables = variables;

  /// [onData] callbacks have het to be run
  ///
  /// inlcudes `lifecycle == QueryLifecycle.sideEffectsBlocking`
  bool get sideEffectsArePending =>
      (lifecycle == QueryLifecycle.sideEffectsPending ||
          lifecycle == QueryLifecycle.sideEffectsBlocking);

  /// Closes the query or mutation, or else queues it for closing.
  ///
  /// To preserve Mutation side effects, [close] checks the [lifecycle],
  /// queuing the stream for closing if  [sideEffectsArePending].
  /// You can override this check with `force: true`.
  ///
  /// Returns a [FutureOr] of the resultant lifecycle, either
  /// [QueryLifecycle.sideEffectsBlocking] or [QueryLifecycle.closed]
  FutureOr<QueryLifecycle> close({
    bool force = false,
    bool fromManager = false,
  }) async {
    if (lifecycle == QueryLifecycle.sideEffectsPending && !force) {
      lifecycle = QueryLifecycle.sideEffectsBlocking;
      // stop closing because we're waiting on something
      return lifecycle;
    }

    // `fromManager` is used by the query manager when it wants to close a query to avoid infinite loops
    if (!fromManager) {
      queryManager.closeQuery(this, fromQuery: true);
    }

    stopPolling();

    await controller.close();

    lifecycle = QueryLifecycle.closed;
    return QueryLifecycle.closed;
  }
}
