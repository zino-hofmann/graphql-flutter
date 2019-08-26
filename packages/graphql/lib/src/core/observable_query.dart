import 'dart:async';

import 'package:graphql/src/exceptions/exceptions.dart';
import 'package:meta/meta.dart';

import 'package:graphql/src/core/query_manager.dart';
import 'package:graphql/src/core/query_options.dart';
import 'package:graphql/src/core/query_result.dart';
import 'package:graphql/src/scheduler/scheduler.dart';

typedef OnData = void Function(QueryResult result);

enum QueryLifecycle {
  UNEXECUTED,
  PENDING,
  POLLING,
  POLLING_STOPPED,
  SIDE_EFFECTS_PENDING,
  SIDE_EFFECTS_BLOCKING,

  COMPLETED,
  CLOSED
}

class ObservableQuery {
  ObservableQuery({
    @required this.queryManager,
    @required this.options,
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

  final String queryId;
  final QueryManager queryManager;

  QueryScheduler get scheduler => queryManager.scheduler;

  final Set<StreamSubscription<QueryResult>> _onDataSubscriptions =
      <StreamSubscription<QueryResult>>{};

  /// The most recently seen result from this operation's stream
  QueryResult latestResult;

  QueryLifecycle lifecycle = QueryLifecycle.UNEXECUTED;

  WatchQueryOptions options;

  StreamController<QueryResult> controller;

  Stream<QueryResult> get stream => controller.stream;
  bool get isCurrentlyPolling => lifecycle == QueryLifecycle.POLLING;

  bool get _isRefetchSafe {
    switch (lifecycle) {
      case QueryLifecycle.COMPLETED:
      case QueryLifecycle.POLLING:
      case QueryLifecycle.POLLING_STOPPED:
        return true;

      case QueryLifecycle.PENDING:
      case QueryLifecycle.CLOSED:
      case QueryLifecycle.UNEXECUTED:
      case QueryLifecycle.SIDE_EFFECTS_PENDING:
      case QueryLifecycle.SIDE_EFFECTS_BLOCKING:
        return false;
    }
    return false;
  }

  /// Attempts to refetch, returning `true` if successful
  bool refetch() {
    if (_isRefetchSafe) {
      queryManager.refetchQuery(queryId);
      return true;
    }
    return false;
  }

  bool get isRebroadcastSafe {
    switch (lifecycle) {
      case QueryLifecycle.PENDING:
      case QueryLifecycle.COMPLETED:
      case QueryLifecycle.POLLING:
      case QueryLifecycle.POLLING_STOPPED:
        return true;

      case QueryLifecycle.UNEXECUTED: // this might be ok
      case QueryLifecycle.CLOSED:
      case QueryLifecycle.SIDE_EFFECTS_PENDING:
      case QueryLifecycle.SIDE_EFFECTS_BLOCKING:
        return false;
    }
    return false;
  }

  void onListen() {
    if (_latestWasEagerlyFetched) {
      _latestWasEagerlyFetched = false;

      // eager results are resolved synchronously,
      // so we have to add them manually now that
      // the stream is available
      if (!controller.isClosed && latestResult != null) {
        controller.add(latestResult);
      }
      return;
    }
    if (options.fetchResults) {
      fetchResults();
    }
  }

  MultiSourceResult fetchResults() {
    final MultiSourceResult allResults =
        queryManager.fetchQueryAsMultiSourceResult(queryId, options);
    latestResult ??= allResults.eagerResult;

    // if onData callbacks have been registered,
    // they are waited on by default
    lifecycle = _onDataSubscriptions.isNotEmpty
        ? QueryLifecycle.SIDE_EFFECTS_PENDING
        : QueryLifecycle.PENDING;

    if (options.pollInterval != null && options.pollInterval > 0) {
      startPolling(options.pollInterval);
    }

    return allResults;
  }

  /// fetch more results and then merge them according to the updateQuery method.
  /// the results will then be added to to stream for the widget to re-build
  void fetchMore(FetchMoreOptions fetchMoreOptions) async {
    // fetch more and udpate
    assert(fetchMoreOptions.updateQuery != null);

    final combinedOptions = QueryOptions(
      fetchPolicy: FetchPolicy.noCache,
      errorPolicy: options.errorPolicy,
      document: fetchMoreOptions.document ?? options.document,
      context: options.context,
      variables: {
        ...options.variables,
        ...fetchMoreOptions.variables,
      },
    );

    // stream old results with a loading indicator
    addResult(QueryResult(
      data: latestResult.data,
      loading: true,
    ));

    QueryResult fetchMoreResult = await queryManager.query(combinedOptions);

    try {
      // combine the query with the new query, using the function provided by the user
      fetchMoreResult.data = fetchMoreOptions.updateQuery(
        latestResult.data,
        fetchMoreResult.data,
      );
      assert(fetchMoreResult.data != null, 'updateQuery result cannot be null');
      // stream the new results and rebuild
      queryManager.addQueryResult(
        queryId,
        fetchMoreResult,
        writeToCache: true,
      );
    } catch (error) {
      if (fetchMoreResult.hasGraphqlErrors) {
        // because the updateQuery failure might have been because of these errors,
        // we just add them to the old errors
        latestResult.exception = coalesceErrors(
          exception: latestResult.exception,
          graphqlErrors: fetchMoreResult.graphqlErrors,
        );

        queryManager.addQueryResult(
          queryId,
          latestResult,
          writeToCache: true,
        );
        return;
      } else {
        // TODO merge results OperationException
        rethrow;
      }
    }
  }

  /// add a result to the stream,
  /// copying `loading` and `optimistic`
  /// from the `latestResult` if they aren't set.
  void addResult(QueryResult result) {
    // don't overwrite results due to some async/optimism issue
    if (latestResult != null &&
        latestResult.timestamp.isAfter(result.timestamp)) {
      return;
    }

    if (latestResult != null) {
      result.source ??= latestResult.source;
    }

    if (lifecycle == QueryLifecycle.PENDING && result.optimistic != true) {
      lifecycle = QueryLifecycle.COMPLETED;
    }

    latestResult = result;

    print('${options.operationName} addResult');
    if (options.operationName.contains('UserEventRecords')) {
      print(latestResult.data['eventRecordsThrough']['eventRecords'].length);
    }

    if (!controller.isClosed) {
      controller.add(result);
    }
  }

  // most mutation behavior happens here
  /// call any registered callbacks, then rebroadcast queries
  /// incase the underlying data has changed
  void onData(Iterable<OnData> callbacks) {
    callbacks ??= const <OnData>[];
    StreamSubscription<QueryResult> subscription;

    subscription = stream.listen((QueryResult result) async {
      if (!result.loading) {
        for (final callback in callbacks) {
          await callback(result);
        }

        queryManager.rebroadcastQueries();

        if (!result.optimistic) {
          await subscription.cancel();
          _onDataSubscriptions.remove(subscription);

          if (_onDataSubscriptions.isEmpty) {
            if (lifecycle == QueryLifecycle.SIDE_EFFECTS_BLOCKING) {
              lifecycle = QueryLifecycle.COMPLETED;
              close();
            }
          }
        }
      }
    });

    _onDataSubscriptions.add(subscription);
  }

  void startPolling(int pollInterval) {
    if (options.fetchPolicy == FetchPolicy.cacheFirst ||
        options.fetchPolicy == FetchPolicy.cacheOnly) {
      throw Exception(
        'Queries that specify the cacheFirst and cacheOnly fetch policies cannot also be polling queries.',
      );
    }

    if (isCurrentlyPolling) {
      scheduler.stopPollingQuery(queryId);
    }

    options.pollInterval = pollInterval;
    lifecycle = QueryLifecycle.POLLING;
    scheduler.startPollingQuery(options, queryId);
  }

  void stopPolling() {
    if (isCurrentlyPolling) {
      scheduler.stopPollingQuery(queryId);
      options.pollInterval = null;
      lifecycle = QueryLifecycle.POLLING_STOPPED;
    }
  }

  set variables(Map<String, dynamic> variables) {
    options.variables = variables;
  }

  /// Closes the query or mutation, or else queues it for closing.
  ///
  /// To preserve Mutation side effects, `close` checks the `lifecycle`,
  /// queuing the stream for closing if  `lifecycle == QueryLifecycle.SIDE_EFFECTS_PENDING`.
  /// You can override this check with `force: true`.
  ///
  /// Returns a `FutureOr` of the resultant lifecycle
  /// (`QueryLifecycle.SIDE_EFFECTS_BLOCKING | QueryLifecycle.CLOSED`)
  FutureOr<QueryLifecycle> close({
    bool force = false,
    bool fromManager = false,
  }) async {
    if (lifecycle == QueryLifecycle.SIDE_EFFECTS_PENDING && !force) {
      lifecycle = QueryLifecycle.SIDE_EFFECTS_BLOCKING;
      // stop closing because we're waiting on something
      return lifecycle;
    }

    // `fromManager` is used by the query manager when it wants to close a query to avoid infinite loops
    if (!fromManager) {
      queryManager.closeQuery(this, fromQuery: true);
    }

    for (StreamSubscription<QueryResult> subscription in _onDataSubscriptions) {
      await subscription.cancel();
    }

    stopPolling();

    await controller.close();

    lifecycle = QueryLifecycle.CLOSED;
    return QueryLifecycle.CLOSED;
  }
}
