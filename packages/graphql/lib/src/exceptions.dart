import 'package:meta/meta.dart';

import 'package:gql_link/gql_link.dart' show LinkException;
import 'package:gql_exec/gql_exec.dart' show GraphQLError;

export 'package:gql_exec/gql_exec.dart' show GraphQLError;

/// A failure to find a response from  the cache when cacheOnly=true
@immutable
class CacheMissException extends LinkException {
  CacheMissException(this.message, this.missingKey) : super(null);

  final String message;
  final String missingKey;
}

//
// end cache exceptions
//

/// Exception occurring when an unhandled, non-link exception
/// is thrown during execution
@immutable
class UnknownException extends LinkException {
  String get message => 'Unhandled Client-Side Exception: $originalException';

  const UnknownException(
    dynamic originalException,
  ) : super(originalException);
}

class OperationException implements Exception {
  /// Any graphql errors returned from the operation
  List<GraphQLError> graphqlErrors = [];

  // generalize to include cache error, etc
  /// Errors encountered during execution such as network or cache errors
  LinkException linkException;

  OperationException({
    this.linkException,
    Iterable<GraphQLError> graphqlErrors = const [],
  }) : this.graphqlErrors = graphqlErrors.toList();

  void addError(GraphQLError error) => graphqlErrors.add(error);

  String toString() => [
        if (linkException != null) 'LinkException: ${linkException}',
        if (graphqlErrors.isNotEmpty) 'GraphQL Errors:',
        ...graphqlErrors.map((e) => e.toString()),
      ].join('\n');
}

/// `(graphqlErrors?, exception?) => exception?`
///
/// merges both optional graphqlErrors and an optional container
/// into a single optional container
/// NOTE: NULL returns expected
OperationException coalesceErrors({
  List<GraphQLError> graphqlErrors,
  LinkException linkException,
  OperationException exception,
}) {
  if (exception != null ||
      linkException != null ||
      (graphqlErrors != null && graphqlErrors.isNotEmpty)) {
    return OperationException(
      linkException: linkException ?? exception?.linkException,
      graphqlErrors: [
        if (graphqlErrors != null) ...graphqlErrors,
        if (exception?.graphqlErrors != null) ...exception.graphqlErrors
      ],
    );
  }
  return null;
}
