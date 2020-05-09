// TODO temporarily taken from gql https://github.com/gql-dart/gql/pull/103
import "dart:async";
import "package:async/async.dart";
import "package:gql_link/gql_link.dart";
import "package:gql_exec/gql_exec.dart";

/// A handler of GraphQL errors.
typedef ErrorHandler = Stream<Response> Function(
  Request request,
  NextLink forward,
  Response response,
);

/// A handler of Link Exceptions.
typedef ExceptionHandler = Stream<Response> Function(
  Request request,
  NextLink forward,
  LinkException exception,
);

/// [ErrorLink] allows interception of GraphQL errors (using [onGraphQLError])
/// and [LinkException]s (using [onException]).
///
/// In both cases [ErrorLink] transfers control over to the handler which may
/// return a new stream to discard the original stream. If the handler returns
/// `null`, the original stream is left intact and will be allowed to continue
/// streaming new events.
class ErrorLink extends Link {
  final ErrorHandler onGraphQLError;
  final ExceptionHandler onException;

  const ErrorLink({
    this.onGraphQLError,
    this.onException,
  });

  @override
  Stream<Response> request(
    Request request, [
    forward,
  ]) async* {
    await for (final result in Result.captureStream(forward(request))) {
      if (result.isError) {
        final error = result.asError.error;

        if (onException != null && error is LinkException) {
          final stream = onException(request, forward, error);

          if (stream != null) {
            yield* stream;

            return;
          }
        }

        yield* Stream.error(error);
      }

      if (result.isValue) {
        final response = result.asValue.value;
        final errors = response.errors;

        if (onGraphQLError != null && errors != null && errors.isNotEmpty) {
          final stream = onGraphQLError(request, forward, response);

          if (stream != null) {
            yield* stream;

            return;
          }
        }

        yield response;
      }
    }
  }
}
