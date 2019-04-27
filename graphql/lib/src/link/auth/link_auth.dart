import 'dart:async';

import 'package:graphql/src/link/link.dart';
import 'package:graphql/src/link/operation.dart';
import 'package:graphql/src/link/fetch_result.dart';

typedef GetToken = FutureOr<String> Function();

class AuthLink extends Link {
  AuthLink({
    this.getToken,
  }) : super(
          request: (Operation operation, [NextLink forward]) {
            StreamController<FetchResult> controller;

            Future<void> onListen() async {
              try {
                final String token = await getToken();

                operation.setContext(<String, Map<String, String>>{
                  'headers': <String, String>{'Authorization': token}
                });
              } catch (error) {
                controller.addError(error);
              }

              await controller.addStream(forward(operation));
              await controller.close();
            }

            controller = StreamController<FetchResult>(onListen: onListen);

            return controller.stream;
          },
        );

  GetToken getToken;
}
