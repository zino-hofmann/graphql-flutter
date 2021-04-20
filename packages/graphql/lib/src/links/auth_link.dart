import 'dart:async';
import 'package:graphql/client.dart';

import "package:gql_exec/gql_exec.dart";
import "package:gql_http_link/gql_http_link.dart";
import "package:gql_link/gql_link.dart";
import "package:gql_transform_link/gql_transform_link.dart";

typedef _RequestTransformer = FutureOr<Request> Function(Request request);

typedef OnException = FutureOr<String> Function(
  HttpLinkServerException exception,
);

/// Simple header-based authentication link that adds [headerKey]: [getToken()] to every request.
///
/// If a lazy or exception-based authentication link is needed for your use case,
/// implementing your own from the [gql reference auth link] or opening an issue.
///
/// [gql reference auth link]: https://github.com/gql-dart/gql/blob/1884596904a411363165bcf3c7cfa9dcc2a61c26/examples/gql_example_http_auth_link/lib/http_auth_link.dart
class AuthLink extends _AsyncReqTransformLink {
  AuthLink({
    required this.getToken,
    this.headerKey = 'Authorization',
  }) : super(requestTransformer: transform(headerKey, getToken));

  /// Authentication callback. Note – must include prefixes, e.g. `'Bearer $token'`
  final FutureOr<String?> Function() getToken;

  /// Header key to set to the result of [getToken]
  final String headerKey;

  static _RequestTransformer transform(
    String headerKey,
    FutureOr<String?> Function() getToken,
  ) =>
      (Request request) async {
        final token = await getToken();
        return request.updateContextEntry<HttpLinkHeaders>(
          (headers) => HttpLinkHeaders(
            headers: <String, String>{
              ...headers?.headers ?? <String, String>{},
              if (token != null) headerKey: token,
            },
          ),
        );
      };
}

/// Version of [TransformLink] that handles async transforms
class _AsyncReqTransformLink extends Link {
  final _RequestTransformer requestTransformer;

  _AsyncReqTransformLink({
    required this.requestTransformer,
  });

  @override
  Stream<Response> request(
    Request request, [
    NextLink? forward,
  ]) async* {
    final req = await requestTransformer(request);

    yield* forward!(req);
  }
}
