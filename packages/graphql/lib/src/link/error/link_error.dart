import 'dart:async';

import 'package:graphql/src/link/link.dart';
import 'package:graphql/src/link/operation.dart';
import 'package:graphql/src/link/fetch_result.dart';
import 'package:graphql/src/exceptions/exceptions.dart';
import 'package:graphql/src/exceptions/graphql_error.dart';
import 'package:graphql/src/exceptions/operation_exception.dart';

typedef ErrorHandler = void Function(ErrorResponse);

class ErrorResponse {
  ErrorResponse({
    this.operation,
    this.fetchResult,
    this.exception,
  });

  Operation operation;
  FetchResult fetchResult;
  OperationException exception;
}

class ErrorLink extends Link {
  ErrorLink({
    this.errorHandler,
  }) : super(
          request: (Operation operation, [NextLink forward]) {
            StreamController<FetchResult> controller;

            Future<void> onListen() async {
              Stream stream = forward(operation).map((FetchResult fetchResult) {
                if (fetchResult.errors != null) {
                  List<GraphQLError> errors = fetchResult.errors
                      .map((json) => GraphQLError.fromJSON(json))
                      .toList();

                  ErrorResponse response = ErrorResponse(
                    operation: operation,
                    fetchResult: fetchResult,
                    exception: OperationException(graphqlErrors: errors),
                  );

                  errorHandler(response);
                }
                return fetchResult;
              }).handleError((error) {
                ErrorResponse response = ErrorResponse(
                  operation: operation,
                  exception: OperationException(
                    clientException: translateFailure(error),
                  ),
                );

                errorHandler(response);
                throw error;
              });

              await controller.addStream(stream);
              await controller.close();
            }

            controller = StreamController<FetchResult>(onListen: onListen);

            return controller.stream;
          },
        );

  ErrorHandler errorHandler;
}
