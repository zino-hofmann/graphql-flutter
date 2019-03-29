import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;
import 'package:graphql_client/graphql_client.dart' show InMemoryCache;

class InMemoryCacheFlutter extends InMemoryCache {
  InMemoryCacheFlutter()
      : super(storageDirectory: getApplicationDocumentsDirectory());
}
