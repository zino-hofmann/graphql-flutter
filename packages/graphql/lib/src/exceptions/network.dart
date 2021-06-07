import 'package:http/http.dart' as http show ClientException;

import 'package:gql_link/gql_link.dart' show LinkException;

/// Exception occurring when there is a network-level error
class NetworkException extends LinkException {
  NetworkException({
    dynamic originalException,
    this.message,
    required this.uri,
  }) : super(originalException);

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
NetworkException? translateFailure(dynamic failure) {
  if (failure is http.ClientException) {
    return NetworkException(
      originalException: failure,
      message: failure.message,
      uri: failure.uri,
    );
  }
  return null;
}
