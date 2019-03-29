import 'dart:io';
import 'in_memory.dart';

class InMemoryCacheVM extends InMemoryCache {
  InMemoryCacheVM()
      : super(storageDirectory: Future<Directory>.value(Directory.systemTemp));
}
