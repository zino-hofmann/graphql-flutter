import 'dart:io' show SocketException;
import 'dart:io';
import './network_exception_stub.dart' as stub;

export './network_exception_stub.dart' show NetworkException;

stub.NetworkException translateNetworkFailure(dynamic failure) {
  if (failure is SocketException) {
    return stub.NetworkException(
      wrappedException: failure,
      message: failure.message,
      uri: Uri(
        scheme: 'http',
        host: failure.address.host,
        port: failure.port,
      ),
    );
  }
  return stub.translateNetworkFailure(failure);
}
