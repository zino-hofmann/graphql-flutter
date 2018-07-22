import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:graphql_flutter/src/links/link.dart';
import 'package:graphql_flutter/src/links/operation.dart';
import 'package:graphql_flutter/src/links/fetch_result.dart';
import 'package:graphql_flutter/src/links/http/fallback_http_config.dart';

Map<String, dynamic> _selectHttpOptionsAndBody(
  Operation operation,
  Map<String, dynamic> fallbackConfig, [
  Map<String, dynamic> linkConfig,
  Map<String, dynamic> contextConfig,
]) {
  /// Setup fallback defaults
  Map<String, dynamic> options = {
    'headers': <String, dynamic>{},
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
    body['query'] = operation.query;
  }

  return <String, dynamic>{
    'options': options,
    'body': json.encode(body),
  };
}

FetchResult _parseResponse(http.Response response) {
  final int statusCode = response.statusCode;
  final String reasonPhrase = response.reasonPhrase;

  if (statusCode < 200 || statusCode >= 400) {
    throw http.ClientException(
      'Network Error: $statusCode $reasonPhrase',
    );
  }

  // final FetchResult jsonResponse = json.decode(response.body);

  // if (jsonResponse['errors'] != null && jsonResponse['errors'].length > 0) {
  //   throw Exception(
  //     'Error returned by the server in the query' +
  //         jsonResponse['errors'].toString(),
  //   );
  // }

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

Link _createHttpLink({
  String uri,
  http.Client fetch,
  Map<String, dynamic> fetchOptions,
  Map<String, dynamic> credentials,
  Map<String, dynamic> headers,
}) {
  assert(uri != null);

  http.Client fetcher = fetch ?? http.Client();

  Map<String, dynamic> linkConfig = {
    'options': fetchOptions,
    'credentials': credentials,
    'headers': headers,
  };

  return new Link(request: (
    Operation operation, [
    NextLink forward,
  ]) {
    Map<String, dynamic> httpOptionsAndBody = _selectHttpOptionsAndBody(
      operation,
      fallbackHttpConfig,
      linkConfig,
    );

    Map<String, dynamic> options = httpOptionsAndBody['options'];
    Map<String, dynamic> body = httpOptionsAndBody['body'];

    StreamController<FetchResult> controller;

    Future<dynamic> onListen() async {
      http.Response response;

      try {
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
  });
}

class HttpLink extends Link {
  factory HttpLink({
    String uri,
    http.Client fetch,
    Map<String, dynamic> fetchOptions,
    Map<String, dynamic> credentials,
    Map<String, dynamic> headers,
  }) {
    return _createHttpLink(
      uri: uri,
      fetch: fetch,
      fetchOptions: fetchOptions,
      credentials: credentials,
      headers: headers,
    );
  }

  RequestHandler requester;
}
