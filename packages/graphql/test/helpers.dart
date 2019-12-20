import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;

import 'package:graphql/client.dart';

overridePrint(testFn(List<String> log)) => () {
      final log = <String>[];
      final spec = ZoneSpecification(print: (_, __, ___, String msg) {
        log.add(msg);
      });
      return Zone.current.fork(specification: spec).run(() => testFn(log));
    };

NormalizedInMemoryCache getTestCache() => NormalizedInMemoryCache(
      dataIdFromObject: typenameDataIdFromObject,
    );

http.StreamedResponse simpleResponse({@required String body, int status}) {
  final List<int> bytes = utf8.encode(body);
  final Stream<List<int>> stream =
      Stream<List<int>>.fromIterable(<List<int>>[bytes]);

  final http.StreamedResponse r = http.StreamedResponse(stream, status ?? 200);

  return r;
}
