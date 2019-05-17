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

abstract class Link {
  static Link from(List<Link> links) => links.reduce(
        (first, next) => first.concat(next),
      );

  static Link fromHandler(RequestHandler handler) =>
      _RequestHandlerLink(handler);

  Stream<FetchResult> request(Operation operation, [NextLink forward]);

  Link concat(Link next) => _ConcatLink(this, next);
}

class _RequestHandlerLink extends Link {
  _RequestHandlerLink(this._handler);

  RequestHandler _handler;

  @override
  Stream<FetchResult> request(Operation operation, [NextLink forward]) {
    return _handler(operation, forward);
  }
}

class _ConcatLink extends Link {
  _ConcatLink(this._first, this._second);

  Link _first;
  Link _second;

  Stream<FetchResult> request(Operation operation, [NextLink forward]) {
    return _first.request(
      operation,
      (Operation operation) => _second.request(operation, forward),
    );
  }
}

Stream<FetchResult> execute({Link link, Operation operation}) =>
    link.request(operation);
