import 'dart:io' as io show SocketException;

import './network.dart' as base;
export './network.dart' show NetworkException;

/// We wrap [base.translateFailure] to handle io-specific network errors.
///
/// Once `gql_link` has robust http and socket exception handling,
/// this and `./unhandled.dart` can be removed and `./exceptions_next.dart`
/// will be all that is necessary
base.NetworkException? translateFailure(Object failure, StackTrace stackTrace) {
  if (failure is io.SocketException) {
    return base.NetworkException.fromException(
      originalException: failure,
      originalStackTrace: stackTrace,
      message: failure.message,
      uri: Uri(
        scheme: 'http',
        host: failure.address?.host,
        port: failure.port,
      ),
    );
  }
  return base.translateFailure(failure, stackTrace);
}
