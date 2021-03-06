import 'dart:async';

import 'package:graphql/client.dart';

import 'package:mockito/mockito.dart';

class MockLink extends Mock implements Link {
  @override
  Stream<Response> request(Request? request, [NextLink? forward]) =>
      super.noSuchMethod(
        Invocation.method(#request, [request, forward]),
        returnValue: Stream.fromIterable(
          <Response>[],
        ),
      ) as Stream<Response>;
}

const debuggingUnexpectedTestFailures = false;

overridePrint(testFn(List<String> log)) => () {
      final log = <String>[];
      final spec = ZoneSpecification(print: (_, __, ___, String msg) {
        log.add(msg);
      });
      return Zone.current.fork(specification: spec).run(() => testFn(log));
    };

class TestCache extends GraphQLCache {
  bool get returnPartialData => debuggingUnexpectedTestFailures;

  get partialDataPolicy => PartialDataCachePolicy.reject;
}

GraphQLCache getTestCache() => TestCache();
