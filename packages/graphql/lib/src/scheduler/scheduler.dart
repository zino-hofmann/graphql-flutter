import 'dart:async';

import 'package:collection/collection.dart';
import 'package:gql_exec/gql_exec.dart';
import 'package:graphql/src/core/query_manager.dart';
import 'package:graphql/src/core/query_options.dart';
import 'package:graphql/src/core/observable_query.dart';

/// Handles scheduling polling results for each [ObservableQuery] with a `pollInterval`
class QueryScheduler {
  QueryScheduler({
    this.queryManager,
    bool deduplicatePollers = false,
  }) : _deduplicatePollers = deduplicatePollers;

  QueryManager? queryManager;
  final bool _deduplicatePollers;

  /// Map going from query ids to the [WatchQueryOptions] associated with those queries.
  Map<String, WatchQueryOptions> registeredQueries =
      <String, WatchQueryOptions>{};

  /// Map going from poling interval to the query ids that fire on that interval.
  /// These query ids are associated with a [ObservableQuery] in the registeredQueries.
  Map<Duration?, Set<String>> intervalQueries = <Duration?, Set<String>>{};

  /// Map going from polling interval durations to polling timers.
  final Map<Duration?, Timer> _pollingTimers = <Duration?, Timer>{};

  void fetchQueriesOnInterval(
    Timer timer,
    Duration? interval,
  ) {
    intervalQueries[interval]!.retainWhere(
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

        final Duration? pollInterval = registeredQueries[queryId]!.pollInterval;

        return registeredQueries.containsKey(queryId) &&
            pollInterval == interval;
      },
    );

    // if no queries on the interval clean up
    if (intervalQueries[interval]!.isEmpty) {
      intervalQueries.remove(interval);
      _pollingTimers.remove(interval);
      timer.cancel();
      return;
    }

    // fetch each query on the interval
    intervalQueries[interval]!.forEach(queryManager!.refetchQuery<dynamic>);
  }

  void startPollingQuery(
    WatchQueryOptions options,
    String queryId,
  ) {
    assert(
      options.pollInterval != null && options.pollInterval! > Duration.zero,
    );

    final existingEntry = _fastestEntryForRequest(options.asRequest);
    final String? existingQueryId = existingEntry?.key;
    final Duration? existingInterval = existingEntry?.value.pollInterval;

    // Update or add the query in registeredQueries
    registeredQueries[queryId] = options;

    final Duration interval;

    if (existingInterval != null && _deduplicatePollers) {
      if (existingInterval > options.pollInterval!) {
        // The new one is faster, remove the old one and add the new one
        intervalQueries[existingInterval]!.remove(existingQueryId);
        interval = options.pollInterval!;
      } else {
        // The new one is slower or the same. Don't add it to the list
        return;
      }
    } else {
      // If there is no existing interval, we'll add the new one
      interval = options.pollInterval!;
    }

    // Add new query to intervalQueries
    _addInterval(queryId, interval);
  }

  /// Removes the [ObservableQuery] from one of the registered queries.
  /// The fetchQueriesOnInterval will then take care of not firing it anymore.
  void stopPollingQuery(String queryId) {
    final removedQuery = registeredQueries.remove(queryId);

    if (removedQuery == null ||
        removedQuery.pollInterval == null ||
        !_deduplicatePollers) {
      return;
    }

    // If there is a registered query that has the same `asRequest` as this one
    // Add the next fastest duration to the intervalQueries
    final fastestEntry = _fastestEntryForRequest(removedQuery.asRequest);
    final String? fastestQueryId = fastestEntry?.key;
    final Duration? fastestInterval = fastestEntry?.value.pollInterval;

    if (fastestQueryId == null || fastestInterval == null) {
      // There is no other query, return.
      return;
    }

    _addInterval(fastestQueryId, fastestInterval);
  }

  /// Adds a [queryId] to the [intervalQueries] for a specific [interval]
  /// and starts the timer if it doesn't exist.
  void _addInterval(String queryId, Duration interval) {
    final existingSet = intervalQueries[interval];
    if (existingSet != null) {
      existingSet.add(queryId);
    } else {
      intervalQueries[interval] = {queryId};
      _pollingTimers[interval] = Timer.periodic(
          interval, (Timer timer) => fetchQueriesOnInterval(timer, interval));
    }
  }

  /// Returns the fastest query that matches the [request] or null if none exists.
  MapEntry<String, WatchQueryOptions<Object?>>? _fastestEntryForRequest(
      Request request) {
    return registeredQueries.entries
        // All existing queries mapping to the same request.
        .where((entry) =>
            entry.value.asRequest == request &&
            entry.value.pollInterval != null)
        // Ascending is default (shortest poll interval first)
        .sortedBy((entry) => entry.value.pollInterval!)
        .firstOrNull;
  }
}
