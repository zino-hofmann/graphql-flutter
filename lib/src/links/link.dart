import 'dart:async';

import 'package:graphql_flutter/src/links/operation.dart';

typedef Stream<Map<String, dynamic>> NextLink(
  Operation operation,
);

typedef Stream<Map<String, dynamic>> RequestHandler(
  Operation operation, [
  NextLink forward,
]);

Link _concat(
  Link first,
  Link second,
) {
  return new Link(request: (
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

Stream<Map<String, dynamic>> execute({
  Link link,
  Map<String, dynamic> operation,
}) {
  return link.request(
    createOperation(operation),
  );
}
