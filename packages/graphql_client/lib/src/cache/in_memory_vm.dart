import 'dart:io';
import 'in_memory.dart';

class InMemoryCacheVM extends InMemoryCache {
  InMemoryCacheVM({Directory customStorageDirectory})
      : super(customStorageDirectory: customStorageDirectory);

  @override
  Future<Directory> get temporaryDirectory async => Directory.systemTemp;
}
