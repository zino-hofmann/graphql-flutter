import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class InMemoryCache {
  Map<String, dynamic> _inMemoryCache = new Map<String, dynamic>();

  Future<String> get _localStoragePath async {
    final Directory directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localStorageFile async {
    final String path = await _localStoragePath;

    return File('$path/cache.txt');
  }

  Future<File> _writeToStorage() async {
    final File file = await _localStorageFile;
    final String output = json.encode(_inMemoryCache);

    print('STORAGE_OUT:');
    print(output);

    return file.writeAsString(output);
  }

  Future<Map<String, dynamic>> _readFromStorage() async {
    try {
      final File file = await _localStorageFile;
      final String content = await file.readAsString();

      print('STORAGE_IN:');
      print(content);

      return json.decode(content);
    } catch (error) {
      // TODO: handle error
      print(error);

      return new Map<String, dynamic>();
    }
  }

  bool hasEntity(String key) => _inMemoryCache.containsKey(key);

  void save() async {
    print("CACHE: SAVE");

    await _writeToStorage();
  }

  void restore() async {
    _inMemoryCache = await _readFromStorage();
  }

  dynamic read(String key) {
    print("CACHE: READ");

    if (hasEntity(key)) {
      return _inMemoryCache[key];
    }

    return null;
  }

  void write(String key, dynamic value) {
    print("CACHE: WRITE");

    _inMemoryCache[key] = value;
  }

  void reset() {
    print("CACHE: RESET");

    _inMemoryCache.clear();
  }
}
