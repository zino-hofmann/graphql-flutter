import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:graphql/src/core/cancellation_token.dart';

abstract class CancellableHttpClient {
  Future<http.Response> send({
    required Uri uri,
    required String method,
    Map<String, String>? headers,
    Object? body,
    CancellationToken? cancellationToken,
  });
}
