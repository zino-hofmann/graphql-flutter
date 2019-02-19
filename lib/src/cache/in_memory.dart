import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:graphql_flutter/src/cache/cache.dart';

void _recursiveAddAll(
  Map<String, dynamic> oldData,
  Map<String, dynamic> newData,
) {
  newData.forEach((String key, dynamic value) {
    if (oldData.containsKey(key) &&
        oldData[key] is Map &&
        value != null &&
        value is Map) {
      _recursiveAddAll(oldData[key], value);
    } else {
      oldData[key] = value;
    }
  });
}

class InMemoryCache implements Cache {
  InMemoryCache({
    this.customStorageDirectory,
  });

  /// A directory to be used for storage.
  /// This is used for testing, on regular usage
  /// 'path_provider' will provide the storage directory.
  final Directory customStorageDirectory;

  HashMap<String, dynamic> _inMemoryCache = HashMap<String, dynamic>();
  bool _writingToStorage = false;

  /// Reads an entity from the internal HashMap.
  @override
  dynamic read(String key) {
    if (_inMemoryCache.containsKey(key)) {
      return _inMemoryCache[key];
    }

    return null;
  }

  /// Writes an entity to the internal HashMap.
  @override
  void write(String key, dynamic value) {
    if (_inMemoryCache.containsKey(key) &&
        _inMemoryCache[key] is Map &&
        value != null &&
        value is Map) {
      // Avoid overriding a superset with a subset of a field (#155)
      _recursiveAddAll(_inMemoryCache[key], value);
    } else {
      _inMemoryCache[key] = value;
    }
  }

  /// Saves the internal HashMap to a file.
  @override
  Future<void> save() async {
    await _writeToStorage();
  }

  /// Restores the internal HashMap to a file.
  @override
  Future<void> restore() async {
    _inMemoryCache = await _readFromStorage();
  }

  /// Clears the internal HashMap.
  @override
  void reset() {
    _inMemoryCache.clear();
  }

  Future<String> get _localStoragePath async {
    if (customStorageDirectory != null) {
      // Used for testing
      return customStorageDirectory.path;
    }

    final Directory directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localStorageFile async {
    final String path = await _localStoragePath;

    return File('$path/cache.txt');
  }

  Future<dynamic> _writeToStorage() async {
    if (_writingToStorage) {
      return;
    }

    _writingToStorage = true;

    // Catching errors to avoid locking forever.
    // Maybe the device couldn't write in the past
    // but it may in the future.
    try {
      final File file = await _localStorageFile;
      final IOSink sink = file.openWrite();
      _inMemoryCache.forEach((String key, dynamic value) {
        sink.writeln(json.encode(<dynamic>[key, value]));
      });

      await sink.close();

      _writingToStorage = false;
    } catch (err) {
      _writingToStorage = false;

      rethrow;
    }
    return;
  }

  Future<HashMap<String, dynamic>> _readFromStorage() async {
    try {
      final File file = await _localStorageFile;
      final HashMap<String, dynamic> storedHashMap = HashMap<String, dynamic>();

      if (file.existsSync()) {
        final Stream<List<int>> inputStream = file.openRead();

        await for (String line in inputStream
            .transform(utf8.decoder) // Decode bytes to UTF8.
            .transform(
              const LineSplitter(),
            )) {
          final List<dynamic> keyAndValue = json.decode(line) as List<dynamic>;
          storedHashMap[keyAndValue[0] as String] = keyAndValue[1];
        }
      }

      return storedHashMap;
    } on FileSystemException {
      // TODO: handle no such file
      print('Can\'t read file from storage, returning an empty HashMap.');

      return HashMap<String, dynamic>();
    } catch (error) {
      // TODO: handle error
      print(error);

      return HashMap<String, dynamic>();
    }
  }
}
