import 'package:graphql/client.dart';

/// Once `gql_link` has robust http and socket exception handling,
/// these should be the only exceptions we need
import 'package:meta/meta.dart';

import 'package:gql_link/gql_link.dart' show LinkException, ServerException;
import 'package:gql_exec/gql_exec.dart' show GraphQLError, Request, Response;

export 'package:gql_exec/gql_exec.dart' show GraphQLError;
export 'package:normalize/normalize.dart' show PartialDataException;

/// A failure to find a response from  the cache when cacheOnly=true
@immutable
class CacheMissException extends LinkException {
  CacheMissException(this.message, this.request) : super(null);

  final String message;
  final Request request;

  @override
  String toString() => 'CacheMissException($message, $request)';
}

/// A failure due to a data structure mismatch between the data and the expected
/// structure based on the [request] `operation` `document`.
///
/// If [validateStructure] passes, then the mismatch must be due to a cache misconfiguration,
/// [CacheMisconfigurationException].
class MismatchedDataStructureException extends LinkException {
  const MismatchedDataStructureException(
    this.originalException, {
    this.request,
    @required this.data,
  }) : super(originalException);

  final Map<String, dynamic> data;
  final Request request;
  final PartialDataException originalException;

  @override
  String toString() => 'MismatchedDataStructureException('
      '$originalException, '
      'request: ${request}, '
      'data: ${data}, '
      ')';
}

/// Failure occurring when the
/// does not match that of the [request] `operation` `document`.
///
/// This is checked by leveraging `normalize`
@immutable
class CacheMisconfigurationException extends LinkException
    implements MismatchedDataStructureException {
  const CacheMisconfigurationException(
    this.originalException, {
    this.request,
    this.fragmentRequest,
    @required this.data,
  }) : super(originalException);

  final Request request;
  final FragmentRequest fragmentRequest;
  final Map<String, dynamic> data;

  @override
  final PartialDataException originalException;

  @override
  String toString() => [
        'CacheMisconfigurationException(',
        '$originalException, ',
        if (request != null) 'request: ${request}',
        if (fragmentRequest != null) 'fragmentRequest : ${fragmentRequest}',
        'data: ${data}, ',
        ')',
      ].join('');
}

/// Failure occurring when the structure of the [parsedResponse] `data`
/// does not match that of the [request] `operation` `document`.
///
/// This is checked by leveraging `normalize`
@immutable
class UnexpectedResponseStructureException extends ServerException
    implements MismatchedDataStructureException {
  const UnexpectedResponseStructureException(
    this.originalException, {
    @required this.request,
    @required Response parsedResponse,
  }) : super(
            parsedResponse: parsedResponse,
            originalException: originalException);

  @override
  final Request request;

  @override
  get data => parsedResponse.data;

  @override
  final PartialDataException originalException;

  @override
  String toString() => 'UnexpectedResponseStructureException('
      '$originalException, '
      'request: ${request}, '
      'parsedResponse: ${parsedResponse}, '
      ')';
}

/// Exception occurring when an unhandled, non-link exception
/// is thrown during execution
@immutable
class UnknownException extends LinkException {
  String get message => 'Unhandled Client-Side Exception: $originalException';

  const UnknownException(
    dynamic originalException,
  ) : super(originalException);

  @override
  String toString() => "UnknownException($originalException)";
}

/// Container for both [graphqlErrors] returned from the server
/// and any [linkException] that caused a failure.
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

  @override
  String toString() => 'OperationException('
      'linkException: ${linkException}, '
      'graphqlErrors: ${graphqlErrors}'
      ')';
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
