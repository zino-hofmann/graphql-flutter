import 'package:gql_exec/gql_exec.dart';

/// A [ContextEntry] flagging whether a [Request] should be deduplicated by a
/// [DedupeLink] in the link chain.
///
/// [DedupeLink] (from `gql_dedupe_link`, re-exported by this package)
/// deduplicates every request by default: identical, concurrent operations
/// collapse into a single network call. That default has no way to be
/// bypassed per-operation, so an entry of this type gives call sites a way
/// to opt individual queries or mutations out of deduplication, mirroring
/// Apollo Client's per-query `queryDeduplication` option.
///
/// Set it via [BaseOptions.queryDeduplication] (e.g.
/// `QueryOptions(..., queryDeduplication: false)`) and read it from a
/// [DedupeLink]'s `shouldDedupe` predicate. [shouldDedupe] is that
/// predicate, ready to wire in directly:
///
/// ```dart
/// DedupeLink(shouldDedupe: QueryDeduplicationContextEntry.shouldDedupe),
/// ```
///
/// Absent from the [Context] (the default), it should be treated as `true`
/// so existing [DedupeLink] configurations keep deduplicating everything.
class QueryDeduplicationContextEntry extends ContextEntry {
  const QueryDeduplicationContextEntry({this.dedupe = true});

  /// Whether this request should be deduplicated with other in-flight,
  /// identical requests. Defaults to `true`.
  final bool dedupe;

  /// A [DedupeLink] `shouldDedupe` predicate that reads a request's
  /// [QueryDeduplicationContextEntry]: `false` when the entry is present
  /// with `dedupe: false`, `true` otherwise (matching [DedupeLink]'s own
  /// default of deduplicating every request).
  static bool shouldDedupe(Request request) =>
      request.context.entry<QueryDeduplicationContextEntry>()?.dedupe ?? true;

  @override
  List<Object?> get fieldsForEquality => [dedupe];
}
