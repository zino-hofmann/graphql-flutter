import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:graphql/src/core/cancellation_token.dart';
import 'client_interface.dart';

class CancellableHttpClientImpl implements CancellableHttpClient {
  @override
  Future<http.Response> send({
    required Uri uri,
    required String method,
    Map<String, String>? headers,
    Object? body,
    CancellationToken? cancellationToken,
  }) async {
    // Create a new HttpClient for each request so we can close it on cancellation
    final client = HttpClient();

    final HttpClientRequest request = await client.openUrl(method, uri);

    if (headers != null) {
      headers.forEach((key, value) {
        request.headers.add(key, value);
      });
    }

    if (body != null) {
      if (body is String) {
        request.write(body);
      } else if (body is List<int>) {
        request.add(body);
      }
    }

    final completer = Completer<http.Response>();
    StreamSubscription<void>? cancellationSubscription;
    bool isCancelled = false;

    if (cancellationToken != null) {
      cancellationSubscription = cancellationToken.onCancel.listen((_) {
        isCancelled = true;
        // Abort the request if it hasn't been sent yet
        request.abort();
        // Force close the client to terminate any in-flight connections
        client.close(force: true);
        if (!completer.isCompleted) {
          completer.completeError(
            http.ClientException('Request cancelled', uri),
          );
        }
      });
    }

    // Don't start the request if already cancelled
    if (cancellationToken?.isCancelled == true) {
      client.close(force: true);
      throw http.ClientException('Request cancelled', uri);
    }

    try {
      final HttpClientResponse response = await request.close();

      // Check if cancelled while waiting for response headers
      if (isCancelled) {
        response.detachSocket().then((socket) => socket.destroy());
        throw http.ClientException('Request cancelled', uri);
      }

      // Collect response body, checking for cancellation
      final List<int> bytes = [];
      await for (final chunk in response) {
        if (isCancelled) {
          response.detachSocket().then((socket) => socket.destroy());
          throw http.ClientException('Request cancelled', uri);
        }
        bytes.addAll(chunk);
      }

      final result = http.Response.bytes(
        bytes,
        response.statusCode,
        headers: _convertHeaders(response.headers),
        request: http.Request(method, uri),
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );

      if (!completer.isCompleted) {
        completer.complete(result);
      }
    } on HttpException catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(http.ClientException(e.message, uri));
      }
    } catch (e) {
      if (!completer.isCompleted) {
        if (e is http.ClientException) {
          completer.completeError(e);
        } else {
          completer.completeError(http.ClientException(e.toString(), uri));
        }
      }
    } finally {
      cancellationSubscription?.cancel();
      client.close();
    }

    return completer.future;
  }

  Map<String, String> _convertHeaders(HttpHeaders headers) {
    final Map<String, String> result = {};
    headers.forEach((key, values) {
      result[key] = values.join(',');
    });
    return result;
  }
}
