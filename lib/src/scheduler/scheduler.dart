import 'dart:async';

import 'package:graphql_flutter/src/core/query_manager.dart';
import 'package:graphql_flutter/src/core/query_options.dart';
import 'package:graphql_flutter/src/core/observable_query.dart';

class QueryScheduler {
  QueryScheduler({
    this.queryManager,
  });

  QueryManager queryManager;

  /// Map going from query ids to the [WatchQueryOptions] associated with those queries.
  Map<String, WatchQueryOptions> registeredQueries =
      <String, WatchQueryOptions>{};

  /// Map going from poling interval to the query ids that fire on that interval.
  /// These query ids are associated with a [ObservableQuery] in the registeredQueries.
  Map<Duration, List<String>> intervalQueries = <Duration, List<String>>{};

  /// Map going from polling interval durations to polling timers.
  final Map<Duration, Timer> _pollingTimers = <Duration, Timer>{};

  void fetchQueriesOnInterval(
    Timer timer,
    Duration interval,
  ) {
    intervalQueries[interval].retainWhere(
      (String queryId) {
        // If ObservableQuery can't be found from registeredQueries or if it has a
        // different interval, it means that this queryId is no longer registered
        // and should be removed from the list of queries firing on this interval.
        //
        // We don't remove queries from intervalQueries immediately in
        // stopPollingQuery so that we can keep the timer consistent when queries
        // are removed and replaced, and to avoid quadratic behavior when stopping
        // many queries.
        if (registeredQueries[queryId] == null) {
          return false;
        }

        final Duration pollInterval =
            Duration(seconds: registeredQueries[queryId].pollInterval);

        return registeredQueries.containsKey(queryId) &&
            pollInterval == interval;
      },
    );

    // if no queries on the interval clean up
    if (intervalQueries[interval].isEmpty) {
      intervalQueries.remove(interval);
      _pollingTimers.remove(interval);
      timer.cancel();
      return;
    }

    // fetch each query on the interval
    for (String queryId in intervalQueries[interval]) {
      final WatchQueryOptions options = registeredQueries[queryId];
      queryManager.fetchQuery(queryId, options);
    }
  }

  void startPollingQuery(
    WatchQueryOptions options,
    String queryId,
  ) {
    registeredQueries[queryId] = options;

    final Duration interval = Duration(
      seconds: options.pollInterval,
    );

    if (intervalQueries.containsKey(interval)) {
      intervalQueries[interval].add(queryId);
    } else {
      intervalQueries[interval] = <String>[queryId];

      _pollingTimers[interval] = Timer.periodic(
        interval,
        (Timer timer) => fetchQueriesOnInterval(timer, interval),
      );
    }
  }

  /// Removes the [ObservableQuery] from one of the registered queries.
  /// The fetchQueriesOnInterval will then take care of not firing it anymore.
  void stopPollingQuery(String queryId) {
    registeredQueries.remove(queryId);
  }
}
