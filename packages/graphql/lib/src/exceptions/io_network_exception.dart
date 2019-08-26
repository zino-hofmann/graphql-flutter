import 'dart:io' show SocketException;
import './network_exception_stub.dart' as stub;

class NetworkException extends stub.NetworkException {
  SocketException wrappedException;

  NetworkException.from(this.wrappedException);

  String get message => wrappedException.message;
  String get targetAddress => wrappedException.address.address;
  int get targetPort => wrappedException.port;
}

void translateExceptions(stub.VoidCallback block) {
  try {
    block();
  } on SocketException catch (e) {
    throw NetworkException.from(e);
  }
}
