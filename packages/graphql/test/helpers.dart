import 'dart:async';

import 'package:graphql/client.dart';

overridePrint(testFn(List<String> log)) => () {
      final log = <String>[];
      final spec = ZoneSpecification(print: (_, __, ___, String msg) {
        log.add(msg);
      });
      return Zone.current.fork(specification: spec).run(() => testFn(log));
    };

class TestCache extends GraphQLCache {
  bool get returnPartialData => true;
}

GraphQLCache getTestCache() => TestCache();
