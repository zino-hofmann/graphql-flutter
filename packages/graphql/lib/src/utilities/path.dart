import 'dart:async';

import 'package:path_provider/path_provider.dart';

final FutureOr<String> flutterStoragePrefix = (() async {
  return (await getApplicationDocumentsDirectory()).path;
})();
