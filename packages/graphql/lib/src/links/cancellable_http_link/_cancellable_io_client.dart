import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:graphql/src/core/cancellation_token.dart';
import '_cancellable_client_interface.dart';

/// IO implementation of [CancellableHttpClient] using dart:io HttpClient.
///
/// This implementation uses a shared [HttpClient] for connection pooling
/// and tracks active requests to enable cancellation.
class CancellableHttpClientImpl implements CancellableHttpClient {
  final HttpClient _httpClient = HttpClient();

  @override
  Future<http.Response> send(
    http.BaseRequest request, {
    CancellationToken? cancellationToken,
  }) async {
    final completer = Completer<http.Response>();
    StreamSubscription<void>? cancellationSubscription;
    HttpClientRequest? httpClientRequest;
    bool isCancelled = false;

    // Check if already cancelled
    if (cancellationToken?.isCancelled == true) {
      return Future.error(
        http.ClientException('Request cancelled', request.url),
      );
    }

    // Set up cancellation listener
    if (cancellationToken != null) {
      cancellationSubscription = cancellationToken.onCancel.listen((_) {
        isCancelled = true;
        // Abort the request if we have one
        httpClientRequest?.abort();
        if (!completer.isCompleted) {
          completer.completeError(
            http.ClientException('Request cancelled', request.url),
          );
        }
      });
    }

    try {
      // Open the HTTP connection
      httpClientRequest = await _httpClient.openUrl(
        request.method,
        request.url,
      );

      // Check cancellation after opening connection
      if (isCancelled) {
        httpClientRequest.abort();
        if (!completer.isCompleted) {
          completer.completeError(
            http.ClientException('Request cancelled', request.url),
          );
        }
        return completer.future;
      }

      // Handle different request types
      if (request is http.Request) {
        // Set headers
        request.headers.forEach((name, value) {
          httpClientRequest!.headers.add(name, value);
        });
        httpClientRequest.contentLength = request.bodyBytes.length;
        httpClientRequest.add(request.bodyBytes);
      } else if (request is http.MultipartRequest) {
        // For multipart requests, finalize() sets up the Content-Type header
        // with the boundary, so we need to finalize first, then copy headers
        final stream = request.finalize();
        // Now headers includes Content-Type with boundary
        request.headers.forEach((name, value) {
          httpClientRequest!.headers.set(name, value);
        });
        httpClientRequest.contentLength = request.contentLength;
        await httpClientRequest.addStream(stream);
      } else if (request is http.StreamedRequest) {
        // Set headers
        request.headers.forEach((name, value) {
          httpClientRequest!.headers.add(name, value);
        });
        await httpClientRequest.addStream(request.finalize());
      } else {
        // Generic BaseRequest - set headers
        request.headers.forEach((name, value) {
          httpClientRequest!.headers.add(name, value);
        });
      }

      // Check cancellation before sending
      if (isCancelled) {
        httpClientRequest.abort();
        if (!completer.isCompleted) {
          completer.completeError(
            http.ClientException('Request cancelled', request.url),
          );
        }
        return completer.future;
      }

      // Send the request
      final httpClientResponse = await httpClientRequest.close();

      // Check cancellation after getting response
      if (isCancelled) {
        await httpClientResponse.drain<void>();
        if (!completer.isCompleted) {
          completer.completeError(
            http.ClientException('Request cancelled', request.url),
          );
        }
        return completer.future;
      }

      // Read response body with cancellation checks
      final bytes = <int>[];
      await for (final chunk in httpClientResponse) {
        if (isCancelled) {
          if (!completer.isCompleted) {
            completer.completeError(
              http.ClientException('Request cancelled', request.url),
            );
          }
          return completer.future;
        }
        bytes.addAll(chunk);
      }

      // Build http.Response
      final response = http.Response.bytes(
        bytes,
        httpClientResponse.statusCode,
        headers: _flattenHeaders(httpClientResponse.headers),
        request: request,
        isRedirect: httpClientResponse.isRedirect,
        persistentConnection: httpClientResponse.persistentConnection,
        reasonPhrase: httpClientResponse.reasonPhrase,
      );

      if (!completer.isCompleted) {
        completer.complete(response);
      }
    } on HttpException catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(
          http.ClientException(e.message, request.url),
        );
      }
    } catch (e) {
      if (!completer.isCompleted) {
        if (e is http.ClientException) {
          completer.completeError(e);
        } else {
          completer.completeError(
            http.ClientException(e.toString(), request.url),
          );
        }
      }
    } finally {
      await cancellationSubscription?.cancel();
    }

    return completer.future;
  }

  Map<String, String> _flattenHeaders(HttpHeaders headers) {
    final result = <String, String>{};
    headers.forEach((name, values) {
      result[name] = values.join(',');
    });
    return result;
  }

  @override
  void close() {
    _httpClient.close();
  }
}
