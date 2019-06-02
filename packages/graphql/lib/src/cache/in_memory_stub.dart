// @todo refactor this with other in_memory_* files
import 'dart:collection';

import 'package:graphql/src/cache/cache.dart';
import 'package:meta/meta.dart';
class InMemoryCache implements Cache {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @protected
  HashMap<String, dynamic> data = HashMap<String, dynamic>();
}
