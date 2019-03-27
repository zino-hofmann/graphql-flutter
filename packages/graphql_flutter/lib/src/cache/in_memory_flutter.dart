import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:graphql_client/graphql_client.dart'
    show InMemoryCache;

class InMemoryCacheFlutter extends InMemoryCache {
  InMemoryCacheFlutter({Directory customStorageDirectory})
      : super(customStorageDirectory: customStorageDirectory);
  @override
  Future<Directory> get temporaryDirectory async =>
      getApplicationDocumentsDirectory();
}
