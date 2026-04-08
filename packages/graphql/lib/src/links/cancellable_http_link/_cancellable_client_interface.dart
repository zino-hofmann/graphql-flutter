import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:graphql/src/core/cancellation_token.dart';

/// Interface for platform-specific HTTP clients that support cancellation.
abstract class CancellableHttpClient {
  /// Sends an HTTP request with cancellation support.
  ///
  /// If [cancellationToken] is provided and cancelled, the underlying
  /// HTTP request will be aborted and a [http.ClientException] with
  /// 'Request cancelled' message will be thrown.
  Future<http.Response> send(
    http.BaseRequest request, {
    CancellationToken? cancellationToken,
  });

  /// Closes the client and releases any resources.
  void close();
}
