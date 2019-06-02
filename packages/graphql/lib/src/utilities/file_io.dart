import 'dart:async';
import 'dart:io' as io;
import './file.dart' as main;

class FileImpl implements main.File {
  FileImpl._(this._file);

  final io.File _file;
  String get path => _file.path;

  Stream<List<int>> openRead() => _file.openRead();
  Future<int> length() => _file.length();

  factory FileImpl.fromPath(String path) => FileImpl._(io.File(path));
}
