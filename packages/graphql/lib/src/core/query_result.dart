import 'dart:async' show FutureOr;

import 'package:graphql/client.dart';
import 'package:graphql/src/exceptions.dart';
import 'package:meta/meta.dart';

/// The source of the result data contained
///
/// * [loading]: No data has been specified from any source
/// * [cache]: A result has been eagerly resolved from the cache
/// * [optimisticResult]: An optimistic result has been specified
///     May include eager results from the cache.
/// * [network]: The query has been resolved on the network
///
/// Both [optimisticResult] and [cache] sources are considered "Eager" results.
enum QueryResultSource {
  /// No data has been specified from any source
  loading,

  /// A result has been eagerly resolved from the cache
  cache,

  /// An optimistic result has been specified.
  /// May include eager results from the cache
  optimisticResult,

  /// The query has been resolved on the network
  network,
}

extension on QueryResultSource {
  /// Whether this result source is considered "eager" (is [cache] or [optimisticResult])
  bool get isEager => _eagerSources.contains(this);
}

final _eagerSources = {
  QueryResultSource.cache,
  QueryResultSource.optimisticResult
};

class QueryResult {
  QueryResult({
    this.data,
    this.exception,
    @required this.source,
  }) : timestamp = DateTime.now();

  factory QueryResult.loading() =>
      QueryResult(source: QueryResultSource.loading);

  factory QueryResult.optimistic({
    Map<String, dynamic> data,
  }) =>
      QueryResult(
        data: data,
        source: QueryResultSource.optimisticResult,
      );

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
  bool get isLoading => source == QueryResultSource.loading;

  /// Whether an optimistic result has been specified.
  ///
  /// May include eager results from the cache.
  bool get isOptimistic => source == QueryResultSource.optimisticResult;

  /// Whether the response includes an [exception]
  bool get hasException => (exception != null);
}

class MultiSourceResult {
  MultiSourceResult({
    this.eagerResult,
    this.networkResult,
  }) : assert(
          eagerResult.source != QueryResultSource.network,
          'An eager result cannot be gotten from the network',
        ) {
    eagerResult ??= QueryResult.loading();
  }

  QueryResult eagerResult;
  FutureOr<QueryResult> networkResult;
}
