import 'package:http/http.dart' as http;

import './_base_exceptions.dart' show ClientException;

class NetworkException implements ClientException {
  covariant Exception wrappedException;

  final String message;

  final Uri uri;

  NetworkException({
    this.wrappedException,
    this.message,
    this.uri,
  });

  String toString() => 'Failed to connect to $uri: $message';
}

NetworkException translateNetworkFailure(dynamic failure) {
  if (failure is http.ClientException) {
    return NetworkException(
      wrappedException: failure,
      message: failure.message,
      uri: failure.uri,
    );
  }
}
