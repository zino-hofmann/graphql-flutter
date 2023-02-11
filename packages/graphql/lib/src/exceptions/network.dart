import 'package:http/http.dart' as http show ClientException;

import 'package:gql_link/gql_link.dart' show LinkException;

/// Exception occurring when there is a network-level error.
/// This constructor is deprecated, use
/// [NetworkException.fromException] instead.
class NetworkException extends LinkException {
  NetworkException({
    required Object originalException,
    StackTrace originalStackTrace = StackTrace.empty,
    this.message,
    required this.uri,
  }) : super(originalException, originalStackTrace);

  NetworkException.fromException({
    required Object originalException,
    required StackTrace originalStackTrace,
    this.message,
    required this.uri,
  }) : super(originalException, originalStackTrace);

  final String? message;
  final Uri? uri;

  String toString() =>
      'Failed to connect to $uri: ${message ?? originalException}';
}

/// We wrap [base.translateFailure] to handle io-specific network errors.
///
/// Once `gql_link` has robust http and socket exception handling,
/// this and `./network.dart` can be removed and `./exceptions_next.dart`
/// will be all that is necessary
NetworkException? translateFailure(Object failure, StackTrace stackTrace) {
  if (failure is http.ClientException) {
    return NetworkException.fromException(
      originalException: failure,
      originalStackTrace: stackTrace,
      message: failure.message,
      uri: failure.uri,
    );
  }
  return null;
}
