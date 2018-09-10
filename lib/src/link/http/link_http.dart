import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:http/http.dart';

import 'package:graphql_flutter/src/link/link.dart';
import 'package:graphql_flutter/src/link/operation.dart';
import 'package:graphql_flutter/src/link/fetch_result.dart';
import 'package:graphql_flutter/src/link/http/http_config.dart';
import 'package:graphql_flutter/src/link/http/fallback_http_config.dart';

class HttpLink extends Link {
  HttpLink({
    @required String uri,
    bool includeExtensions,
    Client fetch,
    Map<String, String> headers,
    Map<String, dynamic> credentials,
    Map<String, dynamic> fetchOptions,
  }) : super(
          request: (
            Operation operation, [
            NextLink forward,
          ]) {
            final Client fetcher = fetch ?? Client();

            final HttpConfig linkConfig = HttpConfig(
              http: HttpQueryOptions(
                includeExtensions: includeExtensions,
              ),
              options: fetchOptions,
              credentials: credentials,
              headers: headers,
            );

            final Map<String, dynamic> context = operation.getContext();
            HttpConfig contextConfig;

            if (context != null) {
              // TODO: refactor context to use a [HttpConfig] object to avoid dynamic types
              contextConfig = HttpConfig(
                http: HttpQueryOptions(
                  includeExtensions: context['includeExtensions'],
                ),
                options: context['fetchOptions'],
                credentials: context['credentials'],
                headers: context['headers'],
              );
            }

            final HttpOptionsAndBody httpOptionsAndBody =
                _selectHttpOptionsAndBody(
              operation,
              fallbackHttpConfig,
              linkConfig,
              contextConfig,
            );

            final Map<String, dynamic> options = httpOptionsAndBody.options;
            final Map<String, String> httpHeaders = options['headers'];

            StreamController<FetchResult> controller;

            Future<void> onListen() async {
              Response response;

              try {
                // TODO: support multiple http methods
                response = await fetcher.post(
                  uri,
                  headers: httpHeaders,
                  body: httpOptionsAndBody.body,
                );

                operation.setContext(<String, Response>{
                  'response': response,
                });

                final FetchResult parsedResponse = _parseResponse(response);

                controller.add(parsedResponse);
              } catch (error) {
                controller.addError(error);
              }

              await controller.close();
            }

            controller = StreamController<FetchResult>(onListen: onListen);

            return controller.stream;
          },
        );
}

HttpOptionsAndBody _selectHttpOptionsAndBody(
  Operation operation,
  HttpConfig fallbackConfig, [
  HttpConfig linkConfig,
  HttpConfig contextConfig,
]) {
  final Map<String, dynamic> options = <String, dynamic>{
    'headers': <String, String>{},
    'credentials': <String, dynamic>{},
  };
  final HttpQueryOptions http = HttpQueryOptions();

  // http options

  // initialze with fallback http options
  http.addAll(fallbackConfig.http);

  // inject the configured http options
  if (linkConfig.http != null) {
    http.addAll(linkConfig.http);
  }

  // override with context http options
  if (contextConfig.http != null) {
    http.addAll(contextConfig.http);
  }

  // options

  // initialze with fallback options
  options.addAll(fallbackConfig.options);

  // inject the configured options
  if (linkConfig.options != null) {
    options.addAll(linkConfig.options);
  }

  // override with context options
  if (contextConfig.options != null) {
    options.addAll(contextConfig.options);
  }

  // headers

  // initialze with fallback headers
  options['headers'].addAll(fallbackConfig.headers);

  // inject the configured headers
  if (linkConfig.headers != null) {
    options['headers'].addAll(linkConfig.headers);
  }

  // inject the context headers
  if (contextConfig.headers != null) {
    options['headers'].addAll(contextConfig.headers);
  }

  // credentials

  // initialze with fallback credentials
  options['credentials'].addAll(fallbackConfig.credentials);

  // inject the configured credentials
  if (linkConfig.credentials != null) {
    options['credentials'].addAll(linkConfig.credentials);
  }

  // inject the context credentials
  if (contextConfig.credentials != null) {
    options['credentials'].addAll(contextConfig.credentials);
  }

  // the body depends on the http options
  final Map<String, dynamic> body = <String, dynamic>{
    'operationName': operation.operationName,
    'variables': operation.variables,
  };

  // not sending the query (i.e persisted queries)
  if (http.includeExtensions) {
    body['extensions'] = operation.extensions;
  }

  if (http.includeQuery) {
    body['query'] = operation.document;
  }

  return HttpOptionsAndBody(
    options: options,
    body: json.encode(body),
  );
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
  final FetchResult fetchResult = FetchResult();

  if (jsonResponse['errors'] != null) {
    fetchResult.errors = jsonResponse['errors'];
  }

  if (jsonResponse['data'] != null) {
    fetchResult.data = jsonResponse['data'];
  }

  return fetchResult;
}
