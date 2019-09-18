import 'package:graphql/src/exceptions/_base_exceptions.dart';
import './graphql_error.dart';

class OperationException implements Exception {
  /// Any graphql errors returned from the operation
  List<GraphQLError> graphqlErrors = [];

  // generalize to include cache error, etc
  /// Errors encountered during execution such as network or cache errors
  ClientException clientException;

  OperationException({
    this.clientException,
    Iterable<GraphQLError> graphqlErrors = const [],
  }) : this.graphqlErrors = graphqlErrors.toList();

  void addError(GraphQLError error) => graphqlErrors.add(error);

  String toString() => [
        if (clientException != null) 'ClientException: ${clientException}',
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
  ClientException clientException,
  OperationException exception,
}) {
  if (exception != null ||
      clientException != null ||
      (graphqlErrors != null && graphqlErrors.isNotEmpty)) {
    return OperationException(
      clientException: clientException ?? exception?.clientException,
      graphqlErrors: [
        if (graphqlErrors != null) ...graphqlErrors,
        if (exception?.graphqlErrors != null) ...exception.graphqlErrors
      ],
    );
  }
  return null;
}
