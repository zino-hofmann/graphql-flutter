import 'dart:async';

import 'package:graphql_flutter/src/core/query_manager.dart';
import 'package:graphql_flutter/src/core/query_options.dart';
import 'package:graphql_flutter/src/core/observable_query.dart';
import 'package:graphql_flutter/src/core/query_result.dart';

class QueryScheduler {
  QueryManager queryManager;

  /// Map going from query ids to the [WatchQueryOptions] associated with those queries.
  Map<String, WatchQueryOptions> registeredQueries = Map();

  /// Map going from poling interval to the query ids that fire on that interval.
  /// These query ids are associated with a [ObservableQuery] in the registeredQueries.
  Map<Duration, List<String>> intervalQueries = Map();

  /// Map going from polling interval durations to polling timers.
  Map<Duration, Timer> _pollingTimers = Map();

  QueryScheduler({
    this.queryManager,
  });

  void fetchQueriesOnInterval(
    Duration interval,
    Timer timer,
  ) {
    intervalQueries[interval].retainWhere(
      (String queryId) {
        Duration pollInterval =
            Duration(seconds: registeredQueries[queryId].pollInterval);

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
    intervalQueries[interval].forEach((String queryId) async {
      WatchQueryOptions options = registeredQueries[queryId];
      QueryResult queryResult = await queryManager.fetchQuery(options);

      queryManager.getQuery(queryId).controller.add(queryResult);
    });
  }

  void sheduleQuery(
    String queryId,
    WatchQueryOptions options, [
    Duration interval,
  ]) {
    registeredQueries[queryId] = options;

    if (interval == null) {
      Timer.run(() async {
        WatchQueryOptions options = registeredQueries[queryId];
        QueryResult queryResult = await queryManager.fetchQuery(options);

        queryManager.getQuery(queryId).controller.add(queryResult);
      });
    } else {
      if (intervalQueries.containsKey(interval)) {
        intervalQueries[interval].add(queryId);
      } else {
        intervalQueries[interval] = [queryId];

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
