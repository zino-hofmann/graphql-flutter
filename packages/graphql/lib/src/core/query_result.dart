import 'dart:async' show FutureOr;
import 'package:graphql/client.dart';
import 'package:graphql/src/core/_base_options.dart';
import 'package:graphql/src/core/result_parser.dart';
import 'package:meta/meta.dart';

/// The source of the result data contained
///
/// * [loading]: No data has been specified from any source
///   for the _most recent_ operation
/// * [cache]: A result has been eagerly resolved from the cache
/// * [optimisticResult]: An optimistic result has been specified
///   May include eager results from the cache.
/// * [network]: The query has been resolved on the network
///
/// Both [optimisticResult] and [cache] sources are considered "Eager" results.
enum QueryResultSource {
  /// No data has been specified from any source for the _most recent_ operation
  loading,

  /// A result has been eagerly resolved from the cache
  cache,

  /// An optimistic result has been specified.
  /// May include eager results from the cache
  optimisticResult,

  /// The query has been resolved on the network
  network,
}

extension Getters on QueryResultSource {
  /// Whether this result source is considered "eager" (is [cache] or [optimisticResult])
  bool get isEager => _eagerSources.contains(this);
}

final _eagerSources = {
  QueryResultSource.cache,
  QueryResultSource.optimisticResult
};

/// A single operation result
class QueryResult<TParsed extends Object?> {
  @protected
  QueryResult.internal({
    Map<String, dynamic>? data,
    this.exception,
    this.context = const Context(),
    required this.parserFn,
    required this.source,
  }) : timestamp = DateTime.now() {
    _data = data;
  }

  factory QueryResult({
    required BaseOptions<TParsed> options,
    Map<String, dynamic>? data,
    OperationException? exception,
    Context context = const Context(),
    required QueryResultSource source,
  }) =>
      options.createResult(
        source: source,
        data: data,
        exception: exception,
        context: context,
      );

  /// Unexecuted singleton, used as a placeholder for mutations,
  /// etc.
  static final unexecuted = QueryResult.internal(
    source: null,
    parserFn: (d) =>
        throw UnimplementedError("Unexecuted query data can not be parsed."),
  )..timestamp = DateTime.fromMillisecondsSinceEpoch(0);

  factory QueryResult.loading({
    required BaseOptions<TParsed> options,
    Map<String, dynamic>? data,
  }) =>
      options.createResult(
        data: data,
        source: QueryResultSource.loading,
      );

  factory QueryResult.optimistic({
    required BaseOptions<TParsed> options,
    Map<String, dynamic>? data,
  }) =>
      options.createResult(
        data: data,
        source: QueryResultSource.optimisticResult,
      );

  DateTime timestamp;

  /// The source of the result data.
  ///
  /// `null` when unexecuted.
  /// Will be set when encountering an error during any execution attempt
  QueryResultSource? source;

  /// Response data
  Map<String, dynamic>? get data {
    return _data;
  }

  set data(Map<String, dynamic>? data) {
    _data = data;
    _cachedParsedData = null;
  }

  Map<String, dynamic>? _data;
  TParsed? _cachedParsedData;

  /// Response context. Defaults to an empty `Context()`
  Context context;

  OperationException? exception;

  ResultParserFn<TParsed> parserFn;

  /// [data] has yet to be specified from any source
  /// for the _most recent_ operation
  /// (including [QueryResultSource.optimisticResult])
  ///
  /// **NOTE:** query updating methods like `fetchMore` and `refetch` will send
  /// an [isLoading], so it is best practice to check both `isLoading && data != null`
  /// before assuming there is no data that should be displayed.
  bool get isLoading => source == QueryResultSource.loading;

  /// [data] been specified (including [QueryResultSource.optimisticResult])
  bool get isNotLoading => !isLoading;

  /// [data] has been specified as an [QueryResultSource.optimisticResult]
  ///
  /// May include eager results from the cache.
  bool get isOptimistic => source == QueryResultSource.optimisticResult;

  /// [data] has been specified and is **not** an [QueryResultSource.optimisticResult]
  ///
  /// shorthand for `!isLoading && !isOptimistic`
  bool get isConcrete => !isLoading && !isOptimistic;

  /// Whether the response includes an [exception]
  bool get hasException => (exception != null);

  /// If a parserFn is provided, this getter can be used to fetch the parsed data.
  TParsed? get parsedData {
    final data = this.data;
    final parserFn = this.parserFn;
    final cachedParsedData = _cachedParsedData;

    if (data == null) {
      return null;
    }
    if (cachedParsedData != null) {
      return cachedParsedData;
    }
    return _cachedParsedData = parserFn(data);
  }

  @override
  String toString() => 'QueryResult('
      'source: $source, '
      'data: $data, '
      'context: $context, '
      'exception: $exception, '
      'timestamp: $timestamp'
      ')';
}

class MultiSourceResult<TParsed> {
  MultiSourceResult({
    required BaseOptions<TParsed> options,
    QueryResult<TParsed>? eagerResult,
    this.networkResult,
  })  : eagerResult = eagerResult ?? QueryResult.loading(options: options),
        assert(
          eagerResult!.source != QueryResultSource.network,
          'An eager result cannot be gotten from the network',
        );

  QueryResult<TParsed> eagerResult;
  FutureOr<QueryResult<TParsed>>? networkResult;
}
