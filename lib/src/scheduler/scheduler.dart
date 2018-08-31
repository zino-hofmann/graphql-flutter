import 'dart:async';

import 'package:graphql_flutter/src/core/observable_query.dart';

class QueryScheduler {
  /// Map going from query ids to the [ObservableQuery] associated with those queries.
  Map<String, ObservableQuery> registeredQueries = Map();

  /// Map going from poling interval to the query ids that fire on that interval.
  /// These query ids are associated with a [ObservableQuery] in the registeredQueries.
  Map<Duration, List<String>> intervalQueries = Map();

  /// Map going from polling interval durations to polling timers.
  Map<Duration, Timer> _pollingTimers = Map();

  void fetchQueriesOnInterval(
    Duration interval,
    Timer timer,
  ) {
    intervalQueries[interval] = intervalQueries[interval].where(
      (String queryId) {
        Duration pollInterval =
            Duration(seconds: registeredQueries[queryId].options.pollInterval);

        // If ObservableQuery can't be found from registeredQueries or if it has a
        // different interval, it means that this queryId is no longer registered
        // and should be removed from the list of queries firing on this interval.
        //
        // We don't remove queries from intervalQueries immediately in
        // stopPollingQuery so that we can keep the timer consistent when queries
        // are removed and replaced, and to avoid quadratic behavior when stopping
        // many queries.
        return registeredQueries.containsKey(queryId) &&
            pollInterval == interval;
      },
    );

    // if no queries on the interval clean up
    if (intervalQueries[interval].length == 0) {
      intervalQueries.remove(interval);
      _pollingTimers.remove(interval);
      timer.cancel();
      return;
    }

    // fetch each query on the interval
    intervalQueries[interval].forEach((String queryId) {
      ObservableQuery observableQuery = registeredQueries[queryId];

      observableQuery.fetchQuery();
    });
  }

  void sheduleQuery(
    ObservableQuery observableQuery, [
    Duration interval,
  ]) {
    registeredQueries[observableQuery.queryId] = observableQuery;

    if (interval == null) {
      Timer.run(() {
        observableQuery.fetchQuery();
      });
    } else {
      if (intervalQueries.containsKey(interval)) {
        intervalQueries[interval].add(observableQuery.queryId);
      } else {
        intervalQueries[interval] = [observableQuery.queryId];

        _pollingTimers[interval] = Timer.periodic(
          interval,
          (Timer timer) => fetchQueriesOnInterval(interval, timer),
        );
      }
    }
  }

  void stopPollingQuery(String queryId) {
    // remove the [ObservableQuery] from one of the registered queries.
    // The fetchQueriesOnInterval will then take care of not firing it anymore.
    registeredQueries.remove(queryId);
  }
}
