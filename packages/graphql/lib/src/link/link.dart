import 'dart:async';

import 'package:graphql/src/link/fetch_result.dart';
import 'package:graphql/src/link/operation.dart';

typedef NextLink = Stream<FetchResult> Function(
  Operation operation,
);

typedef RequestHandler = Stream<FetchResult> Function(
  Operation operation, [
  NextLink forward,
]);

Link _concat(
  Link first,
  Link second,
) {
  return Link(request: (
    Operation operation, [
    NextLink forward,
  ]) {
    return first.request(operation, (Operation op) {
      return second.request(op, forward);
    });
  });
}

class Link {
  Link({this.request});

  RequestHandler request;

  static Link from(List<Link> links) {
    assert(links.isNotEmpty);
    return links.reduce((first, second) => first.concat(second));
  }

  Link concat(Link next) => _concat(this, next);
}

Stream<FetchResult> execute({Link link, Operation operation}) =>
    link.request(operation);
