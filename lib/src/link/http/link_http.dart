import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';
import 'package:mime/mime.dart';

import 'package:graphql_flutter/src/link/link.dart';
import 'package:graphql_flutter/src/link/operation.dart';
import 'package:graphql_flutter/src/link/fetch_result.dart';
import 'package:graphql_flutter/src/link/http/fallback_http_config.dart';
import 'package:graphql_flutter/src/link/http/http_config.dart';
import 'package:graphql_flutter/src/utilities/helpers.dart' show notNull;

class HttpLink extends Link {
  HttpLink({
    @required String uri,
    bool includeExtensions,

    /// pass on customized httpClient, especially handy for mocking and testing
    Client httpClient,
    Map<String, String> headers,
    Map<String, dynamic> credentials,
    Map<String, dynamic> fetchOptions,
  }) : super(
          // @todo possibly this is a bug in dart analyzer
          // ignore: undefined_named_parameter
          request: (
            Operation operation, [
            NextLink forward,
          ]) {
            if (operation.isSubscription) {
              if (forward == null) {
                throw Exception('This link does not support subscriptions.');
              }
              return forward(operation);
            }

            final Client fetcher = httpClient ?? Client();

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
                  includeExtensions: context['includeExtensions'] as bool,
                ),
                options: context['fetchOptions'] as Map<String, dynamic>,
                credentials: context['credentials'] as Map<String, dynamic>,
                headers: context['headers'] as Map<String, String>,
              );
            }

            final HttpHeadersAndBody httpHeadersAndBody =
                _selectHttpOptionsAndBody(
              operation,
              fallbackHttpConfig,
              linkConfig,
              contextConfig,
            );

            final Map<String, String> httpHeaders = httpHeadersAndBody.headers;

            StreamController<FetchResult> controller;

            Future<void> onListen() async {
              StreamedResponse response;

              try {
                // httpOptionsAndBody.body as String
                final BaseRequest request = await _prepareRequest(
                    uri, httpHeadersAndBody.body, httpHeaders);

                response = await fetcher.send(request);

                operation.setContext(<String, StreamedResponse>{
                  'response': response,
                });
                final FetchResult parsedResponse =
                    await _parseResponse(response);

                controller.add(parsedResponse);
              } catch (error) {
                print(<dynamic>[error.runtimeType, error]);
                controller.addError(error);
              }

              await controller.close();
            }

            controller = StreamController<FetchResult>(onListen: onListen);

            return controller.stream;
          },
        );
}

Map<String, File> _getFileMap(
  dynamic body, {
  Map<String, File> currentMap,
  List<String> currentPath = const <String>[],
}) {
  currentMap ??= <String, File>{};
  if (body is Map<String, dynamic>) {
    final Iterable<MapEntry<String, dynamic>> entries = body.entries;
    for (MapEntry<String, dynamic> element in entries) {
      currentMap.addAll(_getFileMap(
        element.value,
        currentMap: currentMap,
        currentPath: List<String>.from(currentPath)..add(element.key),
      ));
    }
    return currentMap;
  }
  if (body is List<dynamic>) {
    for (int i = 0; i < body.length; i++) {
      currentMap.addAll(_getFileMap(
        body[i],
        currentMap: currentMap,
        currentPath: List<String>.from(currentPath)..add(i.toString()),
      ));
    }
    return currentMap;
  }
  if (body is File) {
    return currentMap..addAll(<String, File>{currentPath.join('.'): body});
  }
  // else should only be either String, num, null; NOTHING else
  return currentMap;
}

Future<BaseRequest> _prepareRequest(
  String url,
  Map<String, dynamic> body,
  Map<String, String> httpHeaders,
) async {
  final Map<String, File> fileMap = _getFileMap(body);
  if (fileMap.isEmpty) {
    final Request r = Request('post', Uri.parse(url));
    r.headers.addAll(httpHeaders);
    r.body = json.encode(body);
    return r;
  }

  final MultipartRequest r = MultipartRequest('post', Uri.parse(url));
  r.headers.addAll(httpHeaders);
  r.fields['operations'] = json.encode(body, toEncodable: (dynamic object) {
    if (object is File) {
      return null;
    }
    return object.toJson();
  });

  final Map<String, List<String>> fileMapping = <String, List<String>>{};
  final List<MultipartFile> fileList = <MultipartFile>[];

  final List<MapEntry<String, File>> fileMapEntries =
      fileMap.entries.toList(growable: false);

  for (int i = 0; i < fileMapEntries.length; i++) {
    final MapEntry<String, File> entry = fileMapEntries[i];
    final String indexString = i.toString();
    fileMapping.addAll(<String, List<String>>{
      indexString: <String>[entry.key],
    });
    final File f = entry.value;
    final String fileName = basename(f.path);
    fileList.add(MultipartFile(
      indexString,
      f.openRead(),
      await f.length(),
      contentType: MediaType.parse(lookupMimeType(fileName)),
      filename: fileName,
    ));
  }

  r.fields['map'] = json.encode(fileMapping);

  r.files.addAll(fileList);
  return r;
}

HttpHeadersAndBody _selectHttpOptionsAndBody(
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

  // initialize with fallback http options
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

  // initialize with fallback options
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

  return HttpHeadersAndBody(
    headers: options['headers'] as Map<String, String>,
    body: body,
  );
}

Future<FetchResult> _parseResponse(StreamedResponse response) async {
  final int statusCode = response.statusCode;

  final Encoding encoding = _determineEncodingFromResponse(response);
  // @todo limit bodyBytes
  final Uint8List responseByte = await response.stream.toBytes();
  final String decodedBody = encoding.decode(responseByte);

  final Map<String, dynamic> jsonResponse =
      json.decode(decodedBody) as Map<String, dynamic>;
  final FetchResult fetchResult = FetchResult();

  if (jsonResponse['errors'] != null) {
    fetchResult.errors = jsonResponse['errors'] as List<dynamic>;
  }

  if (jsonResponse['data'] != null) {
    fetchResult.data = jsonResponse['data'];
  }

  if (fetchResult.data == null && fetchResult.errors == null) {
    if (statusCode < 200 || statusCode >= 400) {
      throw ClientException(
        'Network Error: $statusCode $decodedBody',
      );
    }
    throw ClientException('Invalid response body: $decodedBody');
  }

  return fetchResult;
}

/// Returns the charset encoding for the given response.
///
/// The default fallback encoding is set to UTF-8 according to the IETF RFC4627 standard
/// which specifies the application/json media type:
///   "JSON text SHALL be encoded in Unicode. The default encoding is UTF-8."
Encoding _determineEncodingFromResponse(BaseResponse response,
    [Encoding fallback = utf8]) {
  final String contentType = response.headers['content-type'];

  if (contentType == null) {
    return fallback;
  }

  final MediaType mediaType = MediaType.parse(contentType);
  final String charset = mediaType.parameters['charset'];

  if (charset == null) {
    return fallback;
  }

  final Encoding encoding = Encoding.getByName(charset);

  return encoding == null ? fallback : encoding;
}
