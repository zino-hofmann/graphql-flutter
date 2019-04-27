import 'package:meta/meta.dart';

import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;

import 'package:graphql/client.dart' as client;

const client.StorageProvider storageProvider = getApplicationDocumentsDirectory;

class InMemoryCache extends client.InMemoryCache {
  InMemoryCache() : super(storageProvider: storageProvider);
}

class NormalizedInMemoryCache extends client.NormalizedInMemoryCache {
  NormalizedInMemoryCache({
    @required client.DataIdFromObject dataIdFromObject,
    String prefix = '@cache/reference',
  }) : super(
          dataIdFromObject: dataIdFromObject,
          prefix: prefix,
          storageProvider: storageProvider,
        );
}

class OptimisticCache extends client.OptimisticCache {
  OptimisticCache({
    @required client.DataIdFromObject dataIdFromObject,
    String prefix = '@cache/reference',
  }) : super(
          dataIdFromObject: dataIdFromObject,
          prefix: prefix,
          storageProvider: storageProvider,
        );
}
