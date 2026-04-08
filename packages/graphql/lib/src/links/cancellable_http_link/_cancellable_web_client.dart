import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'package:http/http.dart' as http;
import 'package:graphql/src/core/cancellation_token.dart';
import '_cancellable_client_interface.dart';

/// Web implementation of [CancellableHttpClient] using XMLHttpRequest.
///
/// This implementation uses XMLHttpRequest which supports the abort() method
/// for true HTTP-level cancellation in browsers.
class CancellableHttpClientImpl implements CancellableHttpClient {
  @override
  Future<http.Response> send(
    http.BaseRequest request, {
    CancellationToken? cancellationToken,
  }) async {
    // Check if already cancelled
    if (cancellationToken?.isCancelled == true) {
      throw http.ClientException('Request cancelled', request.url);
    }

    final xhr = web.XMLHttpRequest();
    final completer = Completer<http.Response>();
    StreamSubscription<void>? cancellationSubscription;

    // Set up cancellation listener
    if (cancellationToken != null) {
      cancellationSubscription = cancellationToken.onCancel.listen((_) {
        xhr.abort();
      });
    }

    xhr.open(request.method, request.url.toString());

    // Set headers (except Content-Type for multipart - browser will set it)
    final isMultipart = request is http.MultipartRequest;
    request.headers.forEach((name, value) {
      // Skip Content-Type for multipart so browser sets boundary
      if (isMultipart && name.toLowerCase() == 'content-type') return;
      xhr.setRequestHeader(name, value);
    });

    xhr.onload = ((web.Event e) {
      if (!completer.isCompleted) {
        completer.complete(http.Response(
          xhr.responseText,
          xhr.status,
          headers: _parseHeaders(xhr.getAllResponseHeaders()),
          request: request,
        ));
      }
    }).toJS;

    xhr.onerror = ((web.Event e) {
      if (!completer.isCompleted) {
        completer.completeError(
          http.ClientException('XMLHttpRequest error', request.url),
        );
      }
    }).toJS;

    xhr.onabort = ((web.Event e) {
      if (!completer.isCompleted) {
        completer.completeError(
          http.ClientException('Request cancelled', request.url),
        );
      }
    }).toJS;

    try {
      if (request is http.Request) {
        final bodyBytes = request.bodyBytes;
        if (bodyBytes.isNotEmpty) {
          xhr.send(Uint8List.fromList(bodyBytes).toJS);
        } else {
          xhr.send();
        }
      } else if (request is http.MultipartRequest) {
        // For multipart, use FormData which properly handles file uploads
        final formData = web.FormData();

        // Add fields
        request.fields.forEach((name, value) {
          formData.append(name, value.toJS);
        });

        // Add files
        for (final file in request.files) {
          final bytes = await file.finalize().toBytes();
          final blob = web.Blob(
            [Uint8List.fromList(bytes).toJS].toJS,
            web.BlobPropertyBag(type: file.contentType.mimeType),
          );
          formData.append(
            file.field,
            blob,
            file.filename ?? 'file',
          );
        }

        xhr.send(formData);
      } else if (request is http.StreamedRequest) {
        final bytes = await request.finalize().toBytes();
        xhr.send(Uint8List.fromList(bytes).toJS);
      } else {
        xhr.send();
      }

      return await completer.future;
    } finally {
      await cancellationSubscription?.cancel();
    }
  }

  Map<String, String> _parseHeaders(String headers) {
    final result = <String, String>{};
    final lines = headers.split('\r\n');
    for (final line in lines) {
      final index = line.indexOf(':');
      if (index > 0) {
        final name = line.substring(0, index).trim().toLowerCase();
        final value = line.substring(index + 1).trim();
        result[name] = value;
      }
    }
    return result;
  }

  @override
  void close() {
    // No resources to release for XHR
  }
}
