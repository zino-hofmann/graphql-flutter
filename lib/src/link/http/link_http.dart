import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:http/http.dart';

import 'package:graphql_flutter/src/link/link.dart';
import 'package:graphql_flutter/src/link/operation.dart';
import 'package:graphql_flutter/src/link/fetch_result.dart';
import 'package:graphql_flutter/src/link/http/fallback_http_config.dart';

class HttpLink extends Link {
  HttpLink({
    @required String uri,
    Client fetch,
    Map<String, dynamic> fetchOptions,
    Map<String, dynamic> credentials,
    Map<String, dynamic> headers,
  }) : super(
          request: (
            Operation operation, [
            NextLink forward,
          ]) {
            Client fetcher = fetch ?? Client();

            Map<String, dynamic> linkConfig = {
              'options': fetchOptions ?? <String, dynamic>{},
              'credentials': credentials ?? <String, dynamic>{},
              'headers': headers ?? <String, String>{},
              // TODO: add http as a link option
              'http': <String, dynamic>{},
            };

            Map<String, dynamic> contextConfig = {
              'options': <String, dynamic>{},
              'credentials': <String, dynamic>{},
              'headers': <String, String>{},
              'http': <String, dynamic>{},
            };

            contextConfig.addAll(operation.getContext());

            Map<String, dynamic> httpOptionsAndBody = _selectHttpOptionsAndBody(
              operation,
              fallbackHttpConfig,
              linkConfig,
              contextConfig,
            );

            Map<String, dynamic> options = httpOptionsAndBody['options'];
            String body = httpOptionsAndBody['body'];

            StreamController<FetchResult> controller;

            Future<void> onListen() async {
              Response response;

              try {
                // TODO: support multiple http methods
                response = await fetcher.post(
                  uri,
                  headers: options['headers'],
                  body: body,
                );

                operation.setContext({
                  'response': response,
                });

                final FetchResult parsedResponse = _parseResponse(response);

                controller.add(parsedResponse);
              } catch (error) {
                controller.addError(error);
              }

              controller.close();
            }

            controller = StreamController(onListen: onListen);

            return controller.stream;
          },
        );
}

Map<String, dynamic> _selectHttpOptionsAndBody(
  Operation operation,
  Map<String, dynamic> fallbackConfig, [
  Map<String, dynamic> linkConfig,
  Map<String, dynamic> contextConfig,
]) {
  /// Setup fallback defaults
  Map<String, dynamic> options = {
    'headers': <String, String>{},
    'credentials': <String, dynamic>{},
  };
  options.addAll(fallbackConfig['options']);
  options['headers'].addAll(fallbackConfig['headers']);

  Map<String, dynamic> http = {};
  http.addAll(fallbackConfig['http']);

  /// inject the configured settings
  if (linkConfig != null) {
    options.addAll(linkConfig['options']);
    options['headers'].addAll(linkConfig['headers']);
    options['credentials'].addAll(linkConfig['credentials']);

    http.addAll(linkConfig['http']);
  }

  /// override with context settings
  if (contextConfig != null) {
    options.addAll(contextConfig['options']);
    options['headers'].addAll(contextConfig['headers']);
    options['credentials'].addAll(contextConfig['credentials']);

    http.addAll(contextConfig['http']);
  }

  /// the body depends on the http options
  Map<String, dynamic> body = {
    'operationName': operation.operationName,
    'variables': operation.variables,
  };

  /// not sending the query (i.e persisted queries)
  if (http['includeExtensions']) {
    body['extensions'] = operation.extensions;
  }

  if (http['includeQuery']) {
    body['query'] = operation.document;
  }

  return <String, dynamic>{
    'options': options,
    'body': json.encode(body),
  };
}

FetchResult _parseResponse(Response response) {
  final int statusCode = response.statusCode;
  final String reasonPhrase = response.reasonPhrase;

  if (statusCode < 200 || statusCode >= 400) {
    throw ClientException(
      'Network Error: $statusCode $reasonPhrase',
    );
  }

  final Map<String, dynamic> jsonResponse = json.decode(response.body);
  FetchResult fetchResult = FetchResult();

  if (jsonResponse['errors'] != null) {
    fetchResult.errors = jsonResponse['errors'];
  }

  if (jsonResponse['data'] != null) {
    fetchResult.data = jsonResponse['data'];
  }

  return fetchResult;
}
