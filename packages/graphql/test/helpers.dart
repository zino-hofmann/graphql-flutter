import 'dart:convert';
import 'dart:io' show File, Directory;

import 'package:meta/meta.dart';
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
File tempFile(String fileName) => File(join(Directory.current.path, fileName));
