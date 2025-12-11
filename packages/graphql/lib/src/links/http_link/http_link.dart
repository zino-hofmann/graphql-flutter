import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:gql_exec/gql_exec.dart';
import 'package:gql_link/gql_link.dart';
import 'package:graphql/src/core/cancellation_token.dart';
import 'package:gql_http_link/gql_http_link.dart'
    show HttpLinkHeaders, HttpLinkResponseContext, HttpLinkServerException;

import 'client_interface.dart';
// Conditional import
import 'io_client.dart' if (dart.library.html) 'web_client.dart';

export 'package:gql_http_link/gql_http_link.dart' show HttpLinkHeaders;

class HttpLink extends Link {
  HttpLink(
    this.uri, {
    this.defaultHeaders = const {},
    this.httpClient,
    this.serializer = const RequestSerializer(),
    this.parser = const ResponseParser(),
  }) : _cancellableClient = CancellableHttpClientImpl();

  final String uri;
  final Map<String, String> defaultHeaders;
  final http.Client? httpClient;
  final RequestSerializer serializer;
  final ResponseParser parser;

  final CancellableHttpClient _cancellableClient;

  @override
  Stream<Response> request(Request request, [NextLink? forward]) async* {
    final http.Request httpRequest = await _convertRequest(request);

    // Extract cancellation token from context
    CancellationToken? cancellationToken;
    final contextEntry = request.context.entry<CancellationContextEntry>();
    if (contextEntry != null) {
      cancellationToken = contextEntry.token;
    }

    try {
      final http.Response response;
      if (httpClient != null) {
        // Fallback to provided client (no cancellation support unless client supports it internally?)
        // We can't force cancellation on an arbitrary http.Client
        final streamedResponse = await httpClient!.send(httpRequest);
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // Use our cancellable client
        response = await _cancellableClient.send(
          uri: httpRequest.url,
          method: httpRequest.method,
          headers: httpRequest.headers,
          body: httpRequest.bodyBytes, // or body
          cancellationToken: cancellationToken,
        );
      }

      if (response.statusCode >= 300 ||
          (response.statusCode < 200 && response.statusCode != 0)) {
        throw HttpLinkServerException(
          response: response,
          parsedResponse: Response(
            response: <String, dynamic>{},
            context: Context().withEntry(
              HttpLinkResponseContext(
                statusCode: response.statusCode,
                headers: response.headers,
              ),
            ),
          ),
        );
      }

      final Map<String, dynamic> body;
      try {
        final dynamic decoded = json.decode(response.body);
        body = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      } catch (e) {
        throw HttpLinkServerException(
          response: response,
          parsedResponse: Response(
            response: <String, dynamic>{},
            context: Context().withEntry(
              HttpLinkResponseContext(
                statusCode: response.statusCode,
                headers: response.headers,
              ),
            ),
          ),
        );
      }

      final gqlResponse = parser.parseResponse(body);

      yield Response(
        data: gqlResponse.data,
        errors: gqlResponse.errors,
        context: gqlResponse.context.withEntry(
          HttpLinkResponseContext(
            statusCode: response.statusCode,
            headers: response.headers,
          ),
        ),
        response: body,
      );
    } on http.ClientException catch (e) {
      // Check if this was a cancellation - if so, just return without yielding
      // The QueryManager will handle the cancellation via its own mechanism
      if (cancellationToken != null && cancellationToken.isCancelled) {
        return; // Don't throw, just end the stream
      }
      // Check if the error message indicates cancellation
      if (e.message.contains('abort') ||
          e.message.contains('cancel') ||
          e.message.contains('cancelled')) {
        return; // Don't throw, just end the stream
      }
      throw ServerException(
        originalException: e,
        parsedResponse: null,
      );
    } catch (e) {
      // Check if this was a cancellation - if so, just return without yielding
      if (cancellationToken != null && cancellationToken.isCancelled) {
        return; // Don't throw, just end the stream
      }
      throw ServerException(
        originalException: e,
        parsedResponse: null,
      );
    }
  }

  Future<http.Request> _convertRequest(Request request) async {
    final body = await serializer.serializeRequest(request);
    final httpRequest = http.Request('POST', Uri.parse(uri));

    httpRequest.body = json.encode(body);

    httpRequest.headers.addAll({
      'Content-Type': 'application/json',
      'Accept': '*/*',
    });
    httpRequest.headers.addAll(defaultHeaders);

    // Apply headers from context
    final HttpLinkHeaders? contextHeaders =
        request.context.entry<HttpLinkHeaders>();
    if (contextHeaders != null) {
      httpRequest.headers.addAll(contextHeaders.headers);
    }

    return httpRequest;
  }
}
