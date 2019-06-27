@TestOn("vm")

import 'dart:async';
import 'dart:io';
import 'package:test/test.dart';
import 'package:graphql/src/cache/in_memory_io.dart';

import 'helpers.dart';

void main() {
  group('In memory exception handling', () {
    test('FileSystemException', overridePrint((List<String> log) async {
      final InMemoryCache cache = InMemoryCache(
        storagePrefix: Future.error(FileSystemException()),
      );
      await cache.restore();
      expect(
        log,
        ['Can\'t read file from storage, returning an empty HashMap.'],
      );
    }));
  });
}
