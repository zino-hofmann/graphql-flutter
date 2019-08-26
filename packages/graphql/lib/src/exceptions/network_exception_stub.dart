import './base_exceptions.dart' show ClientException;

typedef VoidCallback = void Function();

class NetworkException implements ClientException {
  covariant Exception wrappedException;

  final String message;

  final String targetAddress;
  final int targetPort;

  NetworkException({
    this.wrappedException,
    this.message,
    this.targetAddress,
    this.targetPort,
  });

  String toString() =>
      'Failed to connect to $targetAddress:$targetPort: $message';
}

void translateExceptions(VoidCallback block) => block();
