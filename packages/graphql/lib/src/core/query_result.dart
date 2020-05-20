import 'dart:async' show FutureOr;

import 'package:graphql/client.dart';
import 'package:graphql/src/exceptions.dart';

/// The source of the result data contained
///
/// * [Loading]: No data has been specified from any source
/// * [Cache]: A result has been eagerly resolved from the cache
/// * [OptimisticResult]: An optimistic result has been specified
///     May include eager results from the cache.
/// * [Network]: The query has been resolved on the network
///
/// Both [OptimisticResult] and [Cache] sources are considered "Eager" results.
enum QueryResultSource {
  /// No data has been specified from any source
  Loading,

  /// A result has been eagerly resolved from the cache
  Cache,

  /// An optimistic result has been specified.
  /// May include eager results from the cache
  OptimisticResult,

  /// The query has been resolved on the network
  Network,
}

extension on QueryResultSource {
  /// Whether this result source is considered "eager" (is [Cache] or [OptimisticResult])
  bool get isEager => _eagerSources.contains(this);
}

final _eagerSources = {
  QueryResultSource.Cache,
  QueryResultSource.OptimisticResult
};

class QueryResult {
  QueryResult({
    this.data,
    this.exception,
    bool loading,
    bool optimistic,
    QueryResultSource source,
  })  : timestamp = DateTime.now(),
        this.source = source ??
            ((loading == true)
                ? QueryResultSource.Loading
                : (optimistic == true)
                    ? QueryResultSource.OptimisticResult
                    : null);

  DateTime timestamp;

  /// The source of the result data.
  ///
  /// null when unexecuted.
  /// Will be set when encountering an error during any execution attempt
  QueryResultSource source;

  /// Response data
  Map<String, dynamic> data;

  OperationException exception;

  /// Whether [data] has yet to be specified from either the cache or network
  bool get isLoading => source == QueryResultSource.Loading;

  /// Whether an optimistic result has been specified.
  ///
  /// May include eager results from the cache.
  bool get isOptimistic => source == QueryResultSource.OptimisticResult;

  /// Whether the response includes an [exception]
  bool get hasException => (exception != null);
}

class MultiSourceResult {
  MultiSourceResult({
    this.eagerResult,
    this.networkResult,
  }) : assert(
          eagerResult.source != QueryResultSource.Network,
          'An eager result cannot be gotten from the network',
        ) {
    eagerResult ??= QueryResult(loading: true);
  }

  QueryResult eagerResult;
  FutureOr<QueryResult> networkResult;
}
