// @todo refactor this with other in_memory_* files
import 'dart:async';
import 'dart:collection';

import 'package:graphql/src/cache/cache.dart';
import 'package:meta/meta.dart';

class InMemoryCache implements Cache {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  InMemoryCache({
    this.storagePrefix = '',
  });

  /// For web/browser, `storagePrefix` is a prefix to the key
  /// for [window.localStorage]
  ///
  /// For vm/flutter, `storagePrefix` is a path to the directory
  /// that can save `cache.txt` file
  ///
  /// For flutter usually provided by
  /// [path_provider.getApplicationDocumentsDirectory]
  ///
  /// @NotNull
  final FutureOr<String> storagePrefix;

  @protected
  HashMap<String, dynamic> data = HashMap<String, dynamic>();
}
