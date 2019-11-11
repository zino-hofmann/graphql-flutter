// @todo refactor this with other in_memory_* files
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:html' show window;

import 'package:meta/meta.dart';

import 'package:graphql/src/cache/cache.dart';
import 'package:graphql/src/utilities/helpers.dart' show deeplyMergeLeft;

class InMemoryCache implements Cache {
  InMemoryCache({
    this.storagePrefix = '',
  }) {
    masterKey = storagePrefix ?? '' + '_graphql_cache';
  }

  final String storagePrefix;
  String masterKey;

  @protected
  HashMap<String, dynamic> data = HashMap<String, dynamic>();

  /// Reads an entity from the internal HashMap.
  @override
  dynamic read(String key) {
    if (data.containsKey(key)) {
      return data[key];
    }

    return null;
  }

  /// Writes an entity to the internal HashMap.
  @override
  void write(String key, dynamic value) {
    if (data.containsKey(key) &&
        data[key] is Map &&
        value != null &&
        value is Map<String, dynamic>) {
      // Avoid overriding a superset with a subset of a field (#155)
      data[key] = deeplyMergeLeft(<Map<String, dynamic>>[
        data[key] as Map<String, dynamic>,
        value,
      ]);
    } else {
      data[key] = value;
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
    data = await _readFromStorage();
  }

  /// Clears the internal HashMap.
  @override
  void reset() {
    data.clear();
  }

  Future<dynamic> _writeToStorage() async {
    window.localStorage[masterKey] = jsonEncode(data);
  }

  Future<HashMap<String, dynamic>> _readFromStorage() async {
    try {
      final decoded = jsonDecode(window.localStorage[masterKey]);
      return HashMap.from(decoded);
    } catch (error) {
      // TODO: handle error
      print(error);

      return HashMap<String, dynamic>();
    }
  }
}
