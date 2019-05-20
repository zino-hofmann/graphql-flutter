// This
import 'dart:mirrors';
import 'dart:convert';
import 'dart:io' show File, Platform, Directory;
import 'dart:typed_data' show Uint8List;

import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' show dirname, join;
import 'package:http/http.dart' as http;

import 'package:graphql/client.dart';

NormalizedInMemoryCache getTestCache() => NormalizedInMemoryCache(
      dataIdFromObject: typenameDataIdFromObject,
      storageProvider: () => Directory.systemTemp.createTempSync('file_test_'),
    );

http.StreamedResponse simpleResponse({@required String body, int status}) {
  final List<int> bytes = utf8.encode(body);
  final Stream<List<int>> stream =
      Stream<List<int>>.fromIterable(<List<int>>[bytes]);

  final http.StreamedResponse r = http.StreamedResponse(stream, status ?? 200);

  return r;
}

class _TestUtils {
  static String _path;

  static String get path {
    if (_path == null) {
      final String basePath =
          dirname((reflectClass(_TestUtils).owner as LibraryMirror).uri.path);
      _path = basePath.endsWith('test') ? basePath : join(basePath, 'test');
    }
    return _path;
  }
}

File tempFile(String fileName) => File(join(_TestUtils.path, fileName));
