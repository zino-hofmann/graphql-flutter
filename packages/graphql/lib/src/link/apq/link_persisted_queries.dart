import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:graphql/client.dart';
import 'package:graphql/src/link/error/link_error.dart';
import 'package:graphql/src/link/link.dart';
import 'package:graphql/src/link/operation.dart';
import 'package:graphql/src/link/fetch_result.dart';
import 'package:graphql/src/exceptions/exceptions.dart' as ex;

final VERSION = 1;

typedef QueryHashGenerator = String Function(DocumentNode query);
typedef DisableChecker = bool Function(ErrorResponse error);

class PersistedQueriesLink extends Link {

  bool _supportsPersistedQueries = true;

  final bool useGETForHashedQueries;
  final QueryHashGenerator queryHasher;
  final DisableChecker disabler;

  PersistedQueriesLink({
    this.useGETForHashedQueries = true,
    this.queryHasher,
    this.disabler,
  }) : super() {
    this.request = (Operation operation, [NextLink forward]) {
      if (forward == null) {
        throw Exception('PersistedQueryLink cannot be the last link in the chain.');
      }

      var hashError;
      if (_supportsPersistedQueries) {
        try {
          operation.extensions.addAll({
            'persistedQuery': {
              'sha256Hash': _getQueryHash(operation.documentNode),
              'version': VERSION,
            },
          });
        } catch (e) {
          hashError = e;
        }
      }

      StreamController<FetchResult> controller;
      Future<void> onListen() async {
        if (hashError != null) {
          return controller.addError(hashError);
        }

        StreamSubscription subscription;
        bool retried = false;
        Map<String, dynamic> originalFetchOptions;
        bool setFetchOptions = false;
        Function retry;
        retry = ({
          FetchResult response,
          NetworkException networkError,
          Function callback,
        }) {
          if (!retried && (response?.errors != null || networkError != null)) {
            retried = true;

            final disableCheckPayload = ErrorResponse(
              operation: operation,
              fetchResult: response,
              exception: OperationException(clientException: networkError),
            );
            // if the server doesn't support persisted queries, don't try anymore
            _supportsPersistedQueries = !_disableCheck(disableCheckPayload);

            // if its not found, we can try it again, otherwise just report the error
            if (_arePersistedQueriesSupported(response) || !_supportsPersistedQueries) {
              // need to recall the link chain
              if (subscription != null) {
                subscription.cancel();
              }

              // actually send the query this time
              operation.setContext({
                'http': {
                  'includeQuery': true,
                  'includeExtensions': _supportsPersistedQueries,
                },
              });
              if (setFetchOptions) {
                operation.setContext({ 'fetchOptions': originalFetchOptions });
              }
              subscription = _attachListener(controller, forward(operation), retry);

              return;
            }
          }

          callback();
        };

        // don't send the query the first time
        operation.setContext({
          'http': {
            'includeQuery': !_supportsPersistedQueries,
            'includeExtensions': _supportsPersistedQueries,
          },
        });

        // If requested, set method to GET if there are no mutations. Remember the
        // original fetchOptions so we can restore them if we fall back to a
        // non-hashed request.
        if (
          useGETForHashedQueries &&
          _supportsPersistedQueries &&
          operation.isQuery
        ) {
          final context = operation.getContext();
          originalFetchOptions = context['fetchOptions'] ?? {};
          operation.setContext( {
            'fetchOptions': { 
              ...originalFetchOptions,
              'method': 'GET',
            },
          });
          setFetchOptions = true;
        }

        subscription = _attachListener(controller, forward(operation), retry);
      }

      controller = StreamController<FetchResult>(onListen: onListen);

      return controller.stream;
    };
  }

  _getQueryHash(DocumentNode query) {
    return queryHasher != null 
      ? queryHasher(query)
      : sha256.convert(utf8.encode(printNode(query))).toString();
  }

  _disableCheck(ErrorResponse error) {
    // in case there is a custom disable function defined use this one
    if (disabler != null) {
      return disabler(error);
    }

    // if the server doesn't support persisted queries, don't try anymore
    if (!_arePersistedQueriesSupported(error.fetchResult)) {
      return true;
    }

    FetchResult response = error.fetchResult;
    // if the server responds with bad request
    // apollo-server responds with 400 for GET and 500 for POST when no query is found
    return response?.statusCode == 400 || response?.statusCode == 500;
  }

  bool _arePersistedQueriesSupported(FetchResult result) {
    return !(result?.errors != null &&
        result.errors.any(
          (err) => err['message'] == 'PersistedQueryNotSupported',
        ));
  } 

  StreamSubscription _attachListener(StreamController<FetchResult> controller,
      Stream<FetchResult> stream, Function retry) {
    return stream.listen(
      (data) {
        retry(response: data, callback: () => controller.add(data));
      },
      onError: (err) {
        if (err is UnhandledFailureWrapper) {
          controller.addError(err);
        } else {
          retry(
              networkError: ex.translateFailure(err),
              callback: () => controller.addError(err));
        }
      },
      onDone: () {
        controller.close();
      },
      cancelOnError: true,
    );
  }
}
