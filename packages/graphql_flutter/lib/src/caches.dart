import 'dart:async' show FutureOr;

import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;

import 'package:graphql/client.dart' as client;

final FutureOr<String> flutterStoragePrefix =
    (() async => (await getApplicationDocumentsDirectory()).path)();

class InMemoryCache extends client.InMemoryCache {
  InMemoryCache({
    FutureOr<String> storagePrefix,
  }) : super(storagePrefix: storagePrefix ?? flutterStoragePrefix);
}

class NormalizedInMemoryCache extends client.NormalizedInMemoryCache {
  NormalizedInMemoryCache({
    @required client.DataIdFromObject dataIdFromObject,
    String prefix = '@cache/reference',
  }) : super(
          dataIdFromObject: dataIdFromObject,
          prefix: prefix,
          storagePrefix: flutterStoragePrefix,
        );
}

class OptimisticCache extends client.OptimisticCache {
  OptimisticCache({
    @required client.DataIdFromObject dataIdFromObject,
    String prefix = '@cache/reference',
  }) : super(
          dataIdFromObject: dataIdFromObject,
          prefix: prefix,
          storagePrefix: flutterStoragePrefix,
        );
}
