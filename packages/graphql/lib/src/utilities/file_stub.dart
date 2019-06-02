import './file.dart' as main;

class FileImpl implements main.File {

  factory FileImpl.fromPath(String path) =>
      throw UnsupportedError('io or html');

  @override
  String get path => throw UnsupportedError('io or html');

  @override
  Future<int> length() => throw UnsupportedError('io or html');

  @override
  Stream<List<int>> openRead() => throw UnsupportedError('io or html');
}
