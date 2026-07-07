/// Local GraphQL test server for the cancellation demo.
///
/// Run with: dart run tool/test_server.dart
///
/// - Responds to any POST with a valid GraphQL JSON response after a
///   configurable delay (default 500 ms, override with --delay=<ms>).
/// - Adds CORS headers so Flutter web on localhost can reach it.
/// - No caching, no CDN, no edge nodes – pure predictable latency.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  final delay = _parseDelay(args);
  final port = _parsePort(args);

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('GraphQL test server listening on http://localhost:${server.port}');
  print('Response delay: ${delay.inMilliseconds} ms');
  print('Press Ctrl+C to stop.\n');

  await for (final request in server) {
    // CORS preflight
    _addCorsHeaders(request.response);

    if (request.method == 'OPTIONS') {
      request.response.statusCode = 204;
      await request.response.close();
      continue;
    }

    final ts = DateTime.now().toString().substring(11, 23);
    print(
        '$ts  ${request.method} ${request.uri} — waiting ${delay.inMilliseconds} ms...');

    // Simulate server-side processing time.
    await Future<void>.delayed(delay);

    final body = jsonEncode({
      'data': {
        'countries': List.generate(
          250,
          (i) => {
            'code': 'C$i',
            'name': 'Country $i',
            'continent': {'name': 'Continent ${i % 7}'},
            'languages': [
              {'name': 'Language ${i % 12}'}
            ],
          },
        ),
      },
    });

    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(body);
    await request.response.close();

    print('$ts  → 200 (${body.length} bytes)');
  }
}

void _addCorsHeaders(HttpResponse response) {
  response.headers
    ..add('Access-Control-Allow-Origin', '*')
    ..add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
    ..add('Access-Control-Allow-Headers',
        'Content-Type, Accept, Cache-Control, Authorization')
    ..add('Access-Control-Max-Age', '86400')
    ..add('Cache-Control', 'no-cache, no-store, must-revalidate');
}

Duration _parseDelay(List<String> args) {
  for (final arg in args) {
    if (arg.startsWith('--delay=')) {
      return Duration(milliseconds: int.parse(arg.substring(8)));
    }
  }
  return const Duration(milliseconds: 500);
}

int _parsePort(List<String> args) {
  for (final arg in args) {
    if (arg.startsWith('--port=')) {
      return int.parse(arg.substring(7));
    }
  }
  return 4000;
}
