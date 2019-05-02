import 'dart:async' show FutureOr;
import 'dart:io' show Directory;

import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;

import 'package:graphql/client.dart' as client;

FutureOr<Directory> flutterStorageProvider() =>
    getApplicationDocumentsDirectory();

class InMemoryCache extends client.InMemoryCache {
  InMemoryCache() : super(storageProvider: flutterStorageProvider);
}

class NormalizedInMemoryCache extends client.NormalizedInMemoryCache {
  NormalizedInMemoryCache({
    @required client.DataIdFromObject dataIdFromObject,
    String prefix = '@cache/reference',
  }) : super(
          dataIdFromObject: dataIdFromObject,
          prefix: prefix,
          storageProvider: flutterStorageProvider,
        );
}

class OptimisticCache extends client.OptimisticCache {
  OptimisticCache({
    @required client.DataIdFromObject dataIdFromObject,
    String prefix = '@cache/reference',
  }) : super(
          dataIdFromObject: dataIdFromObject,
          prefix: prefix,
          storageProvider: flutterStorageProvider,
        );
}
