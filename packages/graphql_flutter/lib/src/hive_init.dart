import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show WidgetsFlutterBinding;

import 'package:hive/hive.dart' show Hive;
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;
import 'package:path/path.dart' show join;

import 'package:graphql/client.dart' show HiveStore;

/// Initializes Hive with the path from [getApplicationDocumentsDirectory].
///
/// You can provide a [subDir] where the boxes should be stored.
///
/// Extracted from [`hive_flutter` source][github]
///
/// [github]: https://github.com/hivedb/hive/blob/5bf355496650017409fef4e9905e8826c5dc5bf3/hive_flutter/lib/src/hive_extensions.dart
Future<void> initHiveForFlutter(
    {String? subDir,
    Iterable<String> boxes = const [HiveStore.defaultBoxName]}) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    var appDir = await getApplicationDocumentsDirectory();
    var path = appDir.path;
    if (subDir != null) {
      path = join(path, subDir);
    }
    Hive.init(path);
  }

  final futures = boxes.map(Hive.openBox);
  await Future.wait(futures);
}
