import 'dart:async';
import 'package:meta/meta.dart';

import "package:gql_exec/gql_exec.dart";
import "package:gql_http_link/gql_http_link.dart";
import "package:gql_link/gql_link.dart";
import "package:gql_error_link/gql_error_link.dart";
import "package:gql_transform_link/gql_transform_link.dart";

// Mostly taken from
// https://github.com/gql-dart/gql/blob/master/examples/gql_example_http_auth_link/lib/http_auth_link.dart
class AuthLink extends Link {
  Link _link;
  String _token;

  final FutureOr Function() getToken;

  final String headerKey;

  AuthLink({
    @required this.getToken,
    this.headerKey = 'Authorization',
  }) {
    _link = Link.concat(
      ErrorLink(onException: handleException),
      TransformLink(requestTransformer: transformRequest),
    );
  }

  Future<void> updateToken() async {
    _token = await getToken();
  }

  Stream<Response> handleException(
    Request request,
    NextLink forward,
    LinkException exception,
  ) async* {
    if (exception is HttpLinkServerException &&
        exception.response.statusCode == 401) {
      await updateToken();

      yield* forward(request);

      return;
    }

    throw exception;
  }

  Request transformRequest(Request request) =>
      request.updateContextEntry<HttpLinkHeaders>(
        (headers) => HttpLinkHeaders(
          headers: <String, String>{
            ...headers?.headers ?? <String, String>{},
            headerKey: _token,
          },
        ),
      );

  @override
  Stream<Response> request(Request request, [forward]) async* {
    if (_token == null) {
      await updateToken();
    }

    yield* _link.request(request, forward);
  }
}
