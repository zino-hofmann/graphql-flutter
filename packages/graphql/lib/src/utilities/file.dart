import 'dart:async';
import 'package:graphql/src/utilities/file_io.dart';
export './file_stub.dart'
    if (dart.library.html) './file_html.dart'
    if (dart.library.io) './file_io.dart';

abstract class File {
  String get path;

  Stream<List<int>> openRead();
  Future<int> length();

  factory File.fromPath(String path) => FileImpl.fromPath(path);
}
