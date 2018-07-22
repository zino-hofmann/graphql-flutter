import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class InMemoryCache {
  HashMap<String, dynamic> _inMemoryCache = HashMap<String, dynamic>();

  Future<String> get _localStoragePath async {
    final Directory directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localStorageFile async {
    final String path = await _localStoragePath;

    return File('$path/cache.txt');
  }

  Future<dynamic> _writeToStorage() async {
    final File file = await _localStorageFile;
    IOSink sink = file.openWrite();

    _inMemoryCache.forEach((key, value) {
      sink.writeln(json.encode([key, value]));
    });

    sink.close();

    return sink.done;
  }

  Future<HashMap<String, dynamic>> _readFromStorage() async {
    try {
      final File file = await _localStorageFile;
      final HashMap<String, dynamic> storedHashMap = HashMap<String, dynamic>();

      if (file.existsSync()) {
        Stream<dynamic> inputStream = file.openRead();

        inputStream
            .transform(utf8.decoder) // Decode bytes to UTF8.
            .transform(LineSplitter()) // Convert stream to individual lines.
            .listen((String line) {
          final List keyAndValue = json.decode(line);

          storedHashMap[keyAndValue[0]] = keyAndValue[1];
        });
      }

      return storedHashMap;
    } on FileSystemException {
      // TODO: handle No such file

      return HashMap<String, dynamic>();
    } catch (error) {
      // TODO: handle error
      print(error);

      return HashMap<String, dynamic>();
    }
  }

  bool hasEntity(String key) => _inMemoryCache.containsKey(key);

  void save() async {
    await _writeToStorage();
  }

  void restore() async {
    _inMemoryCache = await _readFromStorage();
  }

  dynamic read(String key) {
    if (hasEntity(key)) {
      return _inMemoryCache[key];
    }

    return null;
  }

  void write(String key, dynamic value) {
    _inMemoryCache[key] = value;
  }

  void reset() {
    _inMemoryCache.clear();
  }
}
