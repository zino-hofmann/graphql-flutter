import 'dart:async';

import 'package:gql/execution.dart';
import 'package:gql/link.dart';
import 'package:graphql/src/link/http/http_config.dart';

typedef GetToken = FutureOr<String> Function();

class AuthLink implements Link {
  final GetToken getToken;

  AuthLink(this.getToken);

  @override
  Stream<Response> request(
    Request request, [
    NextLink forward,
  ]) {
    StreamController<Response> controller;

    controller = StreamController<Response>(
      onListen: () async {
        Context context;
        try {
          final String token = await getToken();

          final entry = request.context.entry<HttpConfig>(
            HttpConfig(
              headers: <String, String>{},
            ),
          );

          entry.headers.addAll(
            <String, String>{'Authorization': token},
          );

          context = request.context.withEntry(entry);
        } catch (error) {
          controller.addError(error);
        }

        await controller.addStream(
          forward(
            context == null
                ? request
                : Request(
                    operation: request.operation,
                    context: context,
                  ),
          ),
        );
        await controller.close();
      },
    );

    return controller.stream;
  }
}
