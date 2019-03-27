import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:graphql_client/graphql_client.dart'
    show NormalizedInMemoryCache, DataIdFromObject;

class NormalizedInMemoryCacheFlutter extends NormalizedInMemoryCache {
  NormalizedInMemoryCacheFlutter({
    DataIdFromObject dataIdFromObject,
    String prefix,
  }) : super(dataIdFromObject: dataIdFromObject, prefix: prefix);
  @override
  Future<Directory> get temporaryDirectory async =>
      getApplicationDocumentsDirectory();
}
