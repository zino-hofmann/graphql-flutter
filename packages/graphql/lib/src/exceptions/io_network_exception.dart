import 'dart:io' show SocketException;
import 'dart:io';
import './network_exception_stub.dart' as stub;

class NetworkException extends stub.NetworkException {
  SocketException wrappedException;

  NetworkException.from(this.wrappedException);

  String get message => wrappedException.message;
  Uri get uri => Uri(
        host: wrappedException.address.host,
        port: wrappedException.port,
      );
}

NetworkException translateNetworkFailure(dynamic failure) {
  if (failure is SocketException) {
    return NetworkException.from(failure);
  }
  return stub.translateNetworkFailure(failure);
}
