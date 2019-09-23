import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:gql/execution.dart';
import 'package:gql/language.dart' as lang;
import 'package:gql_http_link/gql_http_link.dart' as gql_http_link;
import 'package:graphql/src/link/http/fallback_http_config.dart';
import 'package:graphql/src/link/http/http_config.dart';
import 'package:graphql/src/utilities/get_from_ast.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:meta/meta.dart';

class HttpLink extends gql_http_link.HttpLink {
  final String uri;
  final HttpConfig _linkConfig;
  final http.Client _fetcher;

  HttpLink({
    @required this.uri,
    bool includeExtensions,

    /// pass on customized httpClient, especially handy for mocking and testing
    http.Client httpClient,
    Map<String, String> headers,
    Map<String, dynamic> credentials,
    Map<String, dynamic> fetchOptions,
  })  : _fetcher = httpClient ?? http.Client(),
        _linkConfig = HttpConfig(
          http: HttpQueryOptions(
            includeExtensions: includeExtensions,
          ),
          options: fetchOptions,
          credentials: credentials,
          headers: headers,
        ),
        super(
          uri,
          httpClient: httpClient,
        );

  @override
  Stream<Response> request(Request request, [forward]) {
    if (isSubscription(request.operation.document)) {
      if (forward == null) {
        throw Exception('This link does not support subscriptions.');
      }
      return forward(request);
    }

    final HttpHeadersAndBody httpHeadersAndBody = _selectHttpOptionsAndBody(
      request,
      fallbackHttpConfig,
      _linkConfig,
      request.context.entry(HttpConfig()),
    );

    StreamController<Response> controller;

    Future<void> onListen() async {
      try {
        // httpOptionsAndBody.body as String
        final http.BaseRequest request = await _prepareRequest(
          uri,
          httpHeadersAndBody.body,
          httpHeadersAndBody.headers,
        );

        controller.add(
          await _parseResponse(
            await _fetcher.send(request),
          ),
        );
      } catch (error) {
        print(<dynamic>[error.runtimeType, error]);
        controller.addError(error);
      }

      await controller.close();
    }

    controller = StreamController<Response>(onListen: onListen);

    return controller.stream;
  }

  Future<Response> _parseResponse(http.StreamedResponse httpResponse) async {
    final int statusCode = httpResponse.statusCode;

    final Encoding encoding = _determineEncodingFromResponse(httpResponse);
    // @todo limit bodyBytes
    final Uint8List responseByte = await httpResponse.stream.toBytes();

    final String decodedBody = encoding.decode(responseByte);

    final Map<String, dynamic> jsonResponse =
        json.decode(decodedBody) as Map<String, dynamic>;
    final Response response = parseResponse(jsonResponse);

    if (response.data == null && response.errors == null) {
      if (statusCode < 200 || statusCode >= 400) {
        throw http.ClientException(
          'Network Error: $statusCode $decodedBody',
        );
      }
      throw http.ClientException('Invalid response body: $decodedBody');
    }

    return response;
  }
}

Future<Map<String, http.MultipartFile>> _getFileMap(
  dynamic body, {
  Map<String, http.MultipartFile> currentMap,
  List<String> currentPath = const <String>[],
}) async {
  currentMap ??= <String, http.MultipartFile>{};
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
  if (body is http.MultipartFile) {
    return currentMap
      ..addAll(<String, http.MultipartFile>{currentPath.join('.'): body});
  }

  // else should only be either String, num, null; NOTHING else
  return currentMap;
}

Future<http.BaseRequest> _prepareRequest(
  String url,
  Map<String, dynamic> body,
  Map<String, String> httpHeaders,
) async {
  final fileMap = await _getFileMap(body);

  if (fileMap.isEmpty) {
    final r = http.Request(
      'post',
      Uri.parse(url),
    );
    r.headers.addAll(httpHeaders);
    r.body = json.encode(body);

    return r;
  }

  final r = http.MultipartRequest(
    'post',
    Uri.parse(url),
  );
  r.headers.addAll(httpHeaders);
  r.fields['operations'] = json.encode(
    body,
    toEncodable: (dynamic object) {
      if (object is http.MultipartFile) {
        return null;
      }

      return object.toJson();
    },
  );

  final fileMapping = <String, List<String>>{};
  final fileList = <http.MultipartFile>[];

  final fileMapEntries = fileMap.entries.toList(growable: false);

  for (int i = 0; i < fileMapEntries.length; i++) {
    final entry = fileMapEntries[i];
    final indexString = i.toString();
    fileMapping.addAll(<String, List<String>>{
      indexString: <String>[entry.key],
    });
    final f = entry.value;
    fileList.add(http.MultipartFile(
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

HttpHeadersAndBody _selectHttpOptionsAndBody(
  Request request,
  HttpConfig fallbackConfig, [
  HttpConfig linkConfig,
  HttpConfig contextConfig,
]) {
  final options = <String, dynamic>{
    'headers': <String, String>{},
    'credentials': <String, dynamic>{},
  };
  final http = HttpQueryOptions();

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
  final body = <String, dynamic>{
    'operationName': request.operation.operationName,
    'variables': request.operation.variables,
  };

  // not sending the query (i.e persisted queries)
//  if (http.includeExtensions) {
//    body['extensions'] = request.extensions;
//  }

  if (http.includeQuery) {
    body['query'] = lang.printNode(request.operation.document);
  }

  return HttpHeadersAndBody(
    headers: options['headers'] as Map<String, String>,
    body: body,
  );
}

/// Returns the charset encoding for the given response.
///
/// The default fallback encoding is set to UTF-8 according to the IETF RFC4627 standard
/// which specifies the application/json media type:
///   "JSON text SHALL be encoded in Unicode. The default encoding is UTF-8."
Encoding _determineEncodingFromResponse(
  http.BaseResponse response, [
  Encoding fallback = utf8,
]) {
  final contentType = response.headers['content-type'];

  if (contentType == null) {
    return fallback;
  }

  final mediaType = MediaType.parse(contentType);
  final charset = mediaType.parameters['charset'];

  if (charset == null) {
    return fallback;
  }

  return Encoding.getByName(charset) ?? fallback;
}
