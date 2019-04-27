import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;
import 'package:graphql/client.dart' show OptimisticCache, StorageProvider;

class GraphqlFlutterCache extends OptimisticCache {
  GraphqlFlutterCache({
    StorageProvider storageProvider,
  }) : super(
          storageProvider: storageProvider ?? getApplicationDocumentsDirectory,
        );
}
