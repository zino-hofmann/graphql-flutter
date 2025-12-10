import 'dart:async';
import 'package:gql_exec/gql_exec.dart';

/// A token that can be used to cancel an in-flight GraphQL operation.
///
/// Create a [CancellationToken] and pass it to operations like [GraphQLClient.query]
/// or [GraphQLClient.mutate] to enable cancellation of those operations.
///
/// {@tool snippet}
/// Basic usage
///
/// ```dart
/// final cancellationToken = CancellationToken();
///
/// // Start a query
/// final resultFuture = client.query(
///   QueryOptions(
///     document: gql('query { ... }'),
///     cancellationToken: cancellationToken,
///   ),
/// );
///
/// // Later, cancel the operation
/// cancellationToken.cancel();
///
/// // The resultFuture will complete with a QueryResult containing
/// // a CancelledException
/// ```
/// {@end-tool}
class CancellationToken {
  bool _isCancelled = false;
  final _controller = StreamController<void>.broadcast();

  /// Whether this token has been cancelled.
  bool get isCancelled => _isCancelled;

  /// A stream that emits when cancellation is requested.
  Stream<void> get onCancel => _controller.stream;

  /// Cancel the operation associated with this token.
  ///
  /// This will cause any in-flight operation to be terminated and complete
  /// with a [CancelledException].
  ///
  /// Calling [cancel] multiple times has no additional effect.
  void cancel() {
    if (!_isCancelled) {
      _isCancelled = true;
      _controller.add(null);
    }
  }

  /// Dispose of this token's resources.
  ///
  /// After calling [dispose], this token should not be used again.
  void dispose() {
    _controller.close();
  }
}

/// Result wrapper that includes both the result future and a cancellation token.
///
/// This allows you to cancel the operation if needed.
class CancellableOperation<T> {
  /// The future that will complete with the operation result.
  final Future<T> result;

  /// The cancellation token that can be used to cancel this operation.
  final CancellationToken cancellationToken;

  CancellableOperation({
    required this.result,
    required this.cancellationToken,
  });

  /// Cancel this operation.
  ///
  /// This is a convenience method that calls [CancellationToken.cancel].
  void cancel() {
    cancellationToken.cancel();
  }
}

/// Context entry that holds a [CancellationToken].
class CancellationContextEntry extends ContextEntry {
  final CancellationToken token;

  const CancellationContextEntry(this.token);

  @override
  List<Object?> get fieldsForEquality => [token];
}
