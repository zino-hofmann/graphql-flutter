import 'dart:async';

import 'package:graphql_flutter/src/link/operation.dart';
import 'package:graphql_flutter/src/link/fetch_result.dart';

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
  Link({
    this.request,
  });

  final RequestHandler request;

  Link concat(Link next) {
    return _concat(this, next);
  }
}

Stream<FetchResult> execute({
  Link link,
  Operation operation,
}) {
  return link.request(operation);
}
