import 'dart:async';
import 'dart:html' as html;
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';

Stream<List<int>> _readFile(html.File file) {
  final reader = html.FileReader();
  final streamController = StreamController<List<int>>();

  reader.onLoad.listen((_) {
    // streamController.add(reader.result);
    streamController.close();
  });

  reader.onError.listen((error) => streamController.addError(error));

  reader.readAsArrayBuffer(file);

  return streamController.stream;
}

MultipartFile multipartFileFrom(html.File f) => MultipartFile(
      '',
      _readFile(f),
      f.size,
      contentType: MediaType.parse(f.type),
      filename: f.name,
    );
