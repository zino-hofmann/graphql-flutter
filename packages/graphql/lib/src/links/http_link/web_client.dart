import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
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
    final request = web.XMLHttpRequest();
    request.open(method, uri.toString());

    if (headers != null) {
      headers.forEach((key, value) {
        request.setRequestHeader(key, value);
      });
    }

    StreamSubscription<void>? cancellationSubscription;
    if (cancellationToken != null) {
      cancellationSubscription = cancellationToken.onCancel.listen((_) {
        request.abort();
      });
    }

    final completer = Completer<http.Response>();

    request.onload = ((web.Event e) {
      completer.complete(http.Response(
        request.responseText,
        request.status,
        headers: _parseHeaders(request.getAllResponseHeaders()),
        request: http.Request(method, uri),
      ));
    }).toJS;

    request.onerror = ((web.Event e) {
      completer
          .completeError(http.ClientException('XMLHttpRequest error', uri));
    }).toJS;

    request.onabort = ((web.Event e) {
      completer.completeError(http.ClientException('Request cancelled', uri));
    }).toJS;

    if (body != null) {
      if (body is String) {
        request.send(body.toJS);
      } else if (body is List<int>) {
        request.send(Uint8List.fromList(body).toJS);
      } else {
        request.send();
      }
    } else {
      request.send();
    }

    try {
      return await completer.future;
    } finally {
      cancellationSubscription?.cancel();
    }
  }

  Map<String, String> _parseHeaders(String headers) {
    final Map<String, String> result = {};
    final lines = headers.split('\r\n');
    for (final line in lines) {
      final index = line.indexOf(':');
      if (index > 0) {
        final key = line.substring(0, index).trim();
        final value = line.substring(index + 1).trim();
        result[key] = value;
      }
    }
    return result;
  }
}
