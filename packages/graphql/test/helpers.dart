import 'dart:async';
import 'dart:convert';
import 'dart:typed_data' show Uint8List;

import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;

import 'package:graphql/client.dart';
import 'package:graphql/src/utilities/file.dart' show File;
import 'package:path/path.dart';

NormalizedInMemoryCache getTestCache() => NormalizedInMemoryCache(
      dataIdFromObject: typenameDataIdFromObject,
      storageProvider: () => null,
    );

http.StreamedResponse simpleResponse({@required String body, int status}) {
  final List<int> bytes = utf8.encode(body);
  final Stream<List<int>> stream =
      Stream<List<int>>.fromIterable(<List<int>>[bytes]);

  final http.StreamedResponse r = http.StreamedResponse(stream, status ?? 200);

  return r;
}

File tempFile(String fileName) => File.fromPath(join('test', fileName));

/// Collects the data of this stream in a [Uint8List].
Future<Uint8List> toBytes(Stream<List<int>> stream) {
  var completer = new Completer<Uint8List>();
  var sink = new ByteConversionSink.withCallback(
      (bytes) => completer.complete(new Uint8List.fromList(bytes)));
  stream.listen(sink.add,
      onError: completer.completeError,
      onDone: sink.close,
      cancelOnError: true);
  return completer.future;
}
