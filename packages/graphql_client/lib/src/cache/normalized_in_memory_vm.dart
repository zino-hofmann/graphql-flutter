import 'dart:io';
import './normalized_in_memory.dart';

class NormalizedInMemoryCacheVM extends NormalizedInMemoryCache {
  NormalizedInMemoryCacheVM({
    DataIdFromObject dataIdFromObject,
    String prefix,
  }) : super(dataIdFromObject: dataIdFromObject, prefix: prefix);
  @override
  Future<Directory> get temporaryDirectory async => Directory.systemTemp;
}
