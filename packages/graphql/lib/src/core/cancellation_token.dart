import 'dart:async';

/// A token that can be used to cancel an in-flight GraphQL operation.
///
/// Create a [CancellationToken] and pass it to [QueryOptions] or
/// [MutationOptions] to enable cancellation of those operations.
///
/// Example:
/// ```dart
/// final token = CancellationToken();
/// final result = client.query(
///   QueryOptions(
///     document: gql('query { ... }'),
///     cancellationToken: token,
///   ),
/// );
/// // Cancel the operation
/// token.cancel();
/// ```
class CancellationToken {
  bool _isCancelled = false;
  final _controller = StreamController<void>.broadcast();

  /// Whether this token has been cancelled.
  bool get isCancelled => _isCancelled;

  /// A stream that emits when cancellation is requested.
  Stream<void> get onCancel => _controller.stream;

  /// Cancel the operation associated with this token.
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

/// Result wrapper that includes both the result future and a
/// way to cancel the operation.
class CancellableOperation<T> {
  /// The future that will complete with the operation result.
  final Future<T> result;

  final CancellationToken _cancellationToken;

  CancellableOperation({
    required this.result,
    required CancellationToken cancellationToken,
  }) : _cancellationToken = cancellationToken;

  /// Cancel this operation.
  void cancel() => _cancellationToken.cancel();
}
