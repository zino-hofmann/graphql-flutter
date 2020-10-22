import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:graphql/src/exceptions/exceptions.dart' as ex;
import 'package:meta/meta.dart';
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';

import 'package:gql/language.dart';
import 'package:graphql/src/utilities/helpers.dart' show notNull;
import 'package:graphql/src/link/link.dart';
import 'package:graphql/src/link/operation.dart';
import 'package:graphql/src/link/fetch_result.dart';
import 'package:graphql/src/link/http/fallback_http_config.dart';
import 'package:graphql/src/link/http/http_config.dart';
import './link_http_helper_deprecated_stub.dart'
    if (dart.library.io) './link_http_helper_deprecated_io.dart';

class HttpLink extends Link {
  HttpLink({
    @required String uri,
    bool includeExtensions,
    bool useGETForQueries = false,

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
            final parsedUri = Uri.parse(uri);

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
                useGETForQueries: useGETForQueries,
              ),
              options: fetchOptions,
              credentials: credentials,
              headers: headers,
            );

            final Map<String, dynamic> context = operation.getContext();
            HttpConfig contextConfig;

            if (context != null) {
              // TODO: for backwards-compatability fallback to overall context for http options
              dynamic httpContext = context['http'] ?? context ?? {};
              // TODO: refactor context to use a [HttpConfig] object to avoid dynamic types
              contextConfig = HttpConfig(
                http: HttpQueryOptions(
                  includeQuery: httpContext['includeQuery'] as bool,
                  includeExtensions: httpContext['includeExtensions'] as bool,
                  useGETForQueries: httpContext['useGETForQueries'] as bool,
                ),
                options: context['fetchOptions'] as Map<String, dynamic>,
                credentials: context['credentials'] as Map<String, dynamic>,
                headers: context['headers'] as Map<String, String>,
              );
            }

            final HttpConfig config = _mergeHttpConfigs(
              fallbackHttpConfig,
              linkConfig,
              contextConfig,
            );

            StreamController<FetchResult> controller;

            Future<void> onListen() async {
              StreamedResponse response;

              try {
                // httpOptionsAndBody.body as String
                final BaseRequest request = await _prepareRequest(parsedUri, operation, config);

                response = await fetcher.send(request);

                operation.setContext(<String, StreamedResponse>{
                  'response': response,
                });
                final FetchResult parsedResponse = await _parseResponse(response);

                controller.add(parsedResponse);
              } catch (failure) {
                // we overwrite socket uri for now:
                // https://github.com/dart-lang/sdk/issues/12693
                dynamic translated = ex.translateFailure(failure);
                if (translated is ex.NetworkException) {
                  translated.uri = parsedUri;
                }
                controller.addError(translated);
              }

              await controller.close();
            }

            controller = StreamController<FetchResult>(onListen: onListen);

            return controller.stream;
          },
        );
}

Future<Map<String, MultipartFile>> _getFileMap(
  dynamic body, {
  Map<String, MultipartFile> currentMap,
  List<String> currentPath = const <String>[],
}) async {
  currentMap ??= <String, MultipartFile>{};
  if (body is Map<String, dynamic>) {
    final Iterable<MapEntry<String, dynamic>> entries = body.entries;
    for (MapEntry<String, dynamic> element in entries) {
      currentMap.addAll(await _getFileMap(
        element.value,
        currentMap: currentMap,
        currentPath: List<String>.from(currentPath)..add(element.key),
      ));
    }
    return currentMap;
  }
  if (body is List<dynamic>) {
    for (int i = 0; i < body.length; i++) {
      currentMap.addAll(await _getFileMap(
        body[i],
        currentMap: currentMap,
        currentPath: List<String>.from(currentPath)..add(i.toString()),
      ));
    }
    return currentMap;
  }
  if (body is MultipartFile) {
    return currentMap
      ..addAll(<String, MultipartFile>{currentPath.join('.'): body});
  }

  // @deprecated, backward compatible only
  // in case the body is io.File
  // in future release, io.File will no longer be supported
  if (isIoFile(body)) {
    return deprecatedHelper(body, currentMap, currentPath);
  }

  // else should only be either String, num, null; NOTHING else
  return currentMap;
}

Future<BaseRequest> _prepareRequest(
  Uri uri,
  Operation operation,
  HttpConfig config,
) async {
  final httpHeaders = config.headers;
  final body = _buildBody(operation, config);

  final Map<String, MultipartFile> fileMap = await _getFileMap(body);
  if (fileMap.isEmpty) {
    if (operation.isQuery && config.http.useGETForQueries) {
      config.options['method'] = 'GET';
    }

    final httpMethod = config.options['method']?.toString()?.toUpperCase() ?? 'POST';
    if (httpMethod == 'GET') {
      uri = uri.replace(queryParameters: body.map((k, v) => MapEntry(k, v is String ? v : json.encode(v))));
    }
    final Request r = Request(httpMethod, uri);
    r.headers.addAll(httpHeaders);
    if (httpMethod != 'GET') {
      r.body = json.encode(body);
    }
    return r;
  }

  final MultipartRequest r = MultipartRequest('POST', uri);
  r.headers.addAll(httpHeaders);
  r.fields['operations'] = json.encode(body, toEncodable: (dynamic object) {
    if (object is MultipartFile) {
      return null;
    }
    // @deprecated, backward compatible only
    // in case the body is io.File
    // in future release, io.File will no longer be supported
    if (isIoFile(object)) {
      return null;
    }
    return object.toJson();
  });

  final Map<String, List<String>> fileMapping = <String, List<String>>{};
  final List<MultipartFile> fileList = <MultipartFile>[];

  final List<MapEntry<String, MultipartFile>> fileMapEntries =
      fileMap.entries.toList(growable: false);

  for (int i = 0; i < fileMapEntries.length; i++) {
    final MapEntry<String, MultipartFile> entry = fileMapEntries[i];
    final String indexString = i.toString();
    fileMapping.addAll(<String, List<String>>{
      indexString: <String>[entry.key],
    });
    final MultipartFile f = entry.value;
    fileList.add(MultipartFile(
      indexString,
      f.finalize(),
      f.length,
      contentType: f.contentType,
      filename: f.filename,
    ));
  }

  r.fields['map'] = json.encode(fileMapping);

  r.files.addAll(fileList);
  return r;
}

HttpConfig _mergeHttpConfigs(
  HttpConfig fallbackConfig, [
  HttpConfig linkConfig,
  HttpConfig contextConfig,
]) {
  // http options
  final HttpQueryOptions httpQueryOptions = HttpQueryOptions();

  // initialize with fallback http options
  httpQueryOptions.addAll(fallbackConfig.http);

  // inject the configured http options
  if (linkConfig.http != null) {
    httpQueryOptions.addAll(linkConfig.http);
  }

  // override with context http options
  if (contextConfig.http != null) {
    httpQueryOptions.addAll(contextConfig.http);
  }

  return HttpConfig(
    http: httpQueryOptions,
    options: {
      ...fallbackConfig.options,
      ...(linkConfig != null ? linkConfig.options ?? {} : {}),
      ...(contextConfig != null ? contextConfig.options ?? {} : {}),
    },
    credentials: {
      ...fallbackConfig.credentials,
      ...(linkConfig != null ? linkConfig.credentials ?? {} : {}),
      ...(contextConfig != null ? contextConfig.credentials ?? {} : {}),
    },
    headers: {
      ...fallbackConfig.headers,
      ...(linkConfig != null ? linkConfig.headers ?? {} : {}),
      ...(contextConfig != null ? contextConfig.headers ?? {} : {}),
    },
  );
}

Map<String, dynamic> _buildBody(
  Operation operation,
  HttpConfig config,
) {
  // the body depends on the http options
  final Map<String, dynamic> body = <String, dynamic>{
    'operationName': operation.operationName,
    'variables': operation.variables,
  }; 

  // not sending the query (i.e persisted queries)
  if (config.http.includeExtensions) {
    body['extensions'] = operation.extensions;
  }

  if (config.http.includeQuery) {
    body['query'] = printNode(operation.documentNode);
  }

  return body;
}

var headerGl;

Future<FetchResult> _parseResponse(StreamedResponse response) async {
  final int statusCode = response.statusCode;
  headerGl = response.headers;
  final Encoding encoding = _determineEncodingFromResponse(response);
  // @todo limit bodyBytes
  final Uint8List responseByte = await response.stream.toBytes();
  final String decodedBody = encoding.decode(responseByte);

  Map<String, dynamic> jsonResponse;
  try {
      jsonResponse = json.decode(decodedBody) as Map<String, dynamic>;
  } catch(e) {
    throw ClientException('Invalid response body: $decodedBody');
  }
  final FetchResult fetchResult = FetchResult(
    statusCode: statusCode,
  );

  if (jsonResponse['errors'] != null) {
    fetchResult.errors =
        (jsonResponse['errors'] as List<dynamic>).where(notNull).toList();
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
