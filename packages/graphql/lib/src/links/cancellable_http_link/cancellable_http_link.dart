import 'dart:async';
import 'dart:convert';

import 'package:gql/ast.dart';
import 'package:gql_exec/gql_exec.dart';
import 'package:gql_link/gql_link.dart';
import 'package:gql_http_link/gql_http_link.dart'
    show HttpLinkServerException, HttpLinkParserException;
import 'package:http/http.dart' as http;
import 'package:graphql/src/core/cancellation_token.dart';
import 'package:graphql/src/exceptions.dart';

export 'package:gql_http_link/gql_http_link.dart'
    show HttpLinkServerException, HttpLinkParserException;

typedef HttpResponseDecoder = FutureOr<Map<String, dynamic>?> Function(
  http.Response httpResponse,
);

/// An HTTP link that supports request cancellation.
///
/// This link provides the same functionality as [HttpLink] from gql_http_link
/// but adds support for cancelling in-flight HTTP requests when a
/// [CancellationToken] is present in the request context.
///
/// Uses [http.AbortableRequest] from the `http` package (>=1.6.0) to perform
/// true network-level cancellation on all platforms. When the cancellation token
/// fires, the `abortTrigger` future completes, causing the standard HTTP client
/// to abort the underlying connection.
///
/// ## Usage
///
/// ```dart
/// final link = CancellableHttpLink('https://api.example.com/graphql');
/// final client = GraphQLClient(
///   cache: GraphQLCache(),
///   link: link,
/// );
///
/// // Use queryCancellable/mutateCancellable for automatic cancellation token:
/// final operation = client.queryCancellable(QueryOptions(...));
/// operation.cancel(); // Actually cancels the HTTP request
///
/// // Or provide a CancellationToken manually:
/// final token = CancellationToken();
/// client.query(QueryOptions(
///   ...,
///   cancellationToken: token,
/// ));
/// token.cancel(); // Actually cancels the HTTP request
/// ```
///
/// ## File Uploads
///
/// This link fully supports file uploads using the GraphQL multipart request
/// specification, the same as the standard HttpLink.
///
/// ## Maintenance
///
/// Keep in sync with `gql_http_link`'s `HttpLink`: this link deliberately
/// mirrors upstream header handling, GET-for-queries encoding, multipart
/// mapping, and response parsing. Behavior changes or bug fixes landing in
/// `gql_http_link.HttpLink` should be reflected here until `abortTrigger`
/// support is upstreamed and this fork can be removed.
class CancellableHttpLink extends Link {
  /// The endpoint URI of the GraphQL service.
  final Uri uri;

  /// Default HTTP headers to include in every request.
  final Map<String, String> defaultHeaders;

  /// Whether to use HTTP GET method for queries (not mutations).
  final bool useGETForQueries;

  /// Serializer for converting GraphQL requests to HTTP request bodies.
  final RequestSerializer serializer;

  /// Parser for converting HTTP response bodies to GraphQL responses.
  final ResponseParser parser;

  /// Decoder for HTTP response bodies.
  final HttpResponseDecoder httpResponseDecoder;

  /// Whether to follow redirects.
  final bool followRedirects;

  late final http.Client _client;

  static final _defaultDecoder =
      const Utf8Decoder().fuse<Object?>(const JsonDecoder());

  static Map<String, dynamic>? _defaultHttpResponseDecode(
    http.Response response,
  ) =>
      _defaultDecoder.convert(response.bodyBytes) as Map<String, dynamic>?;

  /// Creates a new [CancellableHttpLink].
  ///
  /// [uri] is the endpoint of the GraphQL service.
  ///
  /// [defaultHeaders] are HTTP headers included in every request.
  ///
  /// [useGETForQueries] uses HTTP GET for query operations (not mutations).
  ///
  /// [serializer] converts GraphQL requests to HTTP bodies.
  ///
  /// [parser] converts HTTP response bodies to GraphQL responses.
  ///
  /// [httpResponseDecoder] decodes HTTP response bytes to a Map.
  ///
  /// [followRedirects] whether to follow HTTP redirects.
  CancellableHttpLink(
    String uri, {
    this.defaultHeaders = const {},
    this.useGETForQueries = false,
    this.serializer = const RequestSerializer(),
    this.parser = const ResponseParser(),
    this.httpResponseDecoder = _defaultHttpResponseDecode,
    this.followRedirects = false,
  }) : uri = Uri.parse(uri) {
    _client = http.Client();
  }

  @override
  Stream<Response> request(
    Request request, [
    NextLink? forward,
  ]) {
    // Extract cancellation token from context
    CancellationToken? cancellationToken;
    final contextEntry = request.context.entry<CancellationContextEntry>();
    if (contextEntry != null) {
      cancellationToken = contextEntry.token;
    }

    final controller = StreamController<Response>();

    // Run in a zone that handles errors from cancellation race conditions
    runZonedGuarded(() async {
      try {
        final response = await _executeRequest(request, cancellationToken);
        if (!controller.isClosed) {
          controller.add(response);
          controller.close();
        }
      } catch (error, stackTrace) {
        if (controller.isClosed) {
          // Stream already closed, ignore the error
          return;
        }
        // Convert to CancelledException if the request was aborted
        if (error is http.RequestAbortedException ||
            (cancellationToken?.isCancelled == true &&
                error is http.ClientException)) {
          controller.addError(
            const CancelledException('HTTP request was cancelled'),
            stackTrace,
          );
        } else {
          controller.addError(error, stackTrace);
        }
        controller.close();
      }
    }, (error, stackTrace) {
      // Handle any uncaught errors from async operations
      // (e.g., cancellation race conditions)
      if (!controller.isClosed) {
        if (error is http.RequestAbortedException ||
            (cancellationToken?.isCancelled == true &&
                error is http.ClientException)) {
          controller.addError(
            const CancelledException('HTTP request was cancelled'),
            stackTrace,
          );
        } else {
          controller.addError(error, stackTrace);
        }
        controller.close();
      }
      // If controller is closed, silently ignore the error
    });

    return controller.stream;
  }

  Future<Response> _executeRequest(
    Request request,
    CancellationToken? cancellationToken,
  ) async {
    final httpRequest = _prepareRequest(request, cancellationToken);
    final streamedResponse = await _client.send(httpRequest);
    final httpResponse = await http.Response.fromStream(streamedResponse);

    final response = await _parseHttpResponse(httpResponse);

    if (httpResponse.statusCode >= 300 ||
        (response.data == null && response.errors == null)) {
      throw HttpLinkServerException(
        response: httpResponse,
        parsedResponse: response,
        statusCode: httpResponse.statusCode,
      );
    }

    return Response(
      data: response.data,
      errors: response.errors,
      response: response.response,
      context: _updateResponseContext(response, httpResponse),
    );
  }

  /// Converts a gql [Request] into an [http.BaseRequest].
  ///
  /// When a [cancellationToken] is provided, uses [http.AbortableRequest] or
  /// [http.AbortableMultipartRequest] so the standard [http.Client] will abort
  /// the underlying connection when the token fires.
  ///
  /// Note: This method calls [MultipartFile.finalize] on any files in the
  /// request variables. A finalized MultipartFile cannot be reused — if a
  /// retry Link is in the chain, the retry must call [request()] again
  /// (which calls this method with fresh file objects) rather than reusing
  /// the same [http.BaseRequest] instance.
  http.BaseRequest _prepareRequest(
    Request request,
    CancellationToken? cancellationToken,
  ) {
    final abortTrigger = _createAbortTrigger(cancellationToken);

    final body = _encodeAttempter(
      request,
      serializer.serializeRequest,
    )(request);

    final contextHeaders = _getHttpLinkHeaders(request);
    final headers = {
      'Content-Type': 'application/json',
      'Accept': '*/*',
      ...defaultHeaders,
      ...contextHeaders,
    };

    final fileMap = _extractFlattenedFileMap(body);

    final useGetForThisRequest =
        fileMap.isEmpty && useGETForQueries && _isQuery(request);

    if (useGetForThisRequest) {
      final params = _encodeAsUriParams(body);
      final query = params['query'];
      if (query != null) {
        // collapse indentation so it doesn't bloat the GET URL
        params['query'] = query.replaceAll(RegExp(r'\s+'), ' ').trim();
      }
      return http.AbortableRequest(
        'GET',
        uri.replace(queryParameters: params),
        abortTrigger: abortTrigger,
      )..headers.addAll(headers);
    }

    final httpBody = _encodeAttempter(
      request,
      (Map<String, dynamic> body) => json.encode(
        body,
        toEncodable: (dynamic object) =>
            (object is http.MultipartFile) ? null : object.toJson(),
      ),
    )(body);

    if (fileMap.isNotEmpty) {
      final multipartRequest = http.AbortableMultipartRequest(
        'POST',
        uri,
        abortTrigger: abortTrigger,
      )
        ..fields['operations'] = httpBody
        ..headers.addAll(headers);

      // Add files with proper mapping
      final fileMapping = <String, List<String>>{};
      final fileEntries = fileMap.entries.toList();
      for (var i = 0; i < fileEntries.length; i++) {
        final entry = fileEntries[i];
        final indexString = i.toString();
        fileMapping[indexString] = [entry.key];
        final f = entry.value;
        multipartRequest.files.add(http.MultipartFile(
          indexString,
          f.finalize(),
          f.length,
          contentType: f.contentType,
          filename: f.filename,
        ));
      }
      multipartRequest.fields['map'] = json.encode(fileMapping);

      return multipartRequest;
    }

    return http.AbortableRequest('POST', uri, abortTrigger: abortTrigger)
      ..body = httpBody
      ..headers.addAll(headers);
  }

  /// Creates a [Future] that completes when the [cancellationToken] is
  /// cancelled, suitable for passing as [http.AbortableRequest.abortTrigger].
  ///
  /// The returned future completes only when the token actually fires. If the
  /// token is disposed on normal completion (its broadcast controller closes
  /// without emitting), the future is left uncompleted so the happy path
  /// produces no dangling error. A never-completing trigger simply means the
  /// request is never aborted, which is the desired behavior.
  static Future<void>? _createAbortTrigger(CancellationToken? token) {
    if (token == null) return null;
    if (token.isCancelled) return Future<void>.value();

    final completer = Completer<void>();
    late final StreamSubscription<void> subscription;
    subscription = token.onCancel.listen(
      (_) {
        if (!completer.isCompleted) completer.complete();
        subscription.cancel();
      },
      // Token disposed without emitting (normal completion): release the
      // subscription and leave the completer uncompleted.
      onDone: () => subscription.cancel(),
      cancelOnError: false,
    );
    return completer.future;
  }

  Future<Response> _parseHttpResponse(http.Response httpResponse) async {
    try {
      final responseBody = await httpResponseDecoder(httpResponse);
      return parser.parseResponse(responseBody!);
    } catch (e, stackTrace) {
      throw HttpLinkParserException(
        originalException: e,
        originalStackTrace: stackTrace,
        response: httpResponse,
      );
    }
  }

  Context _updateResponseContext(
    Response response,
    http.Response httpResponse,
  ) {
    try {
      return response.context.withEntry(
        HttpLinkResponseContext(
          statusCode: httpResponse.statusCode,
          headers: httpResponse.headers,
        ),
      );
    } catch (e, stackTrace) {
      throw ContextWriteException(
        originalException: e,
        originalStackTrace: stackTrace,
      );
    }
  }

  T Function(V) _encodeAttempter<T, V>(
    Request request,
    T Function(V) encoder,
  ) =>
      (V input) {
        try {
          return encoder(input);
        } catch (e, stackTrace) {
          throw RequestFormatException(
            originalException: e,
            originalStackTrace: stackTrace,
            request: request,
          );
        }
      };

  Map<String, String> _getHttpLinkHeaders(Request request) {
    try {
      final HttpLinkHeaders? linkHeaders = request.context.entry();
      return {
        if (linkHeaders != null) ...linkHeaders.headers,
      };
    } catch (e, stackTrace) {
      throw ContextReadException(
        originalException: e,
        originalStackTrace: stackTrace,
      );
    }
  }

  bool _isQuery(Request request) {
    final definitions = request.operation.document.definitions
        .whereType<OperationDefinitionNode>()
        .toList();
    if (request.operation.operationName != null) {
      definitions.removeWhere(
        (node) => node.name!.value != request.operation.operationName,
      );
    }
    if (definitions.length != 1) return false;
    return definitions.first.type == OperationType.query;
  }

  @override
  Future<void> dispose() async {
    _client.close();
  }
}

Map<String, String> _encodeAsUriParams(Map<String, dynamic> serialized) =>
    serialized.map<String, String>(
      (k, dynamic v) => MapEntry(k, v is String ? v : json.encode(v)),
    );

/// Recursively extract [MultipartFile]s and return them as a normalized map.
Map<String, http.MultipartFile> _extractFlattenedFileMap(
  dynamic body, {
  Map<String, http.MultipartFile>? currentMap,
  List<String> currentPath = const <String>[],
}) {
  currentMap ??= <String, http.MultipartFile>{};
  if (body is Map<String, dynamic>) {
    for (final entry in body.entries) {
      currentMap.addAll(_extractFlattenedFileMap(
        entry.value,
        currentMap: currentMap,
        currentPath: List<String>.from(currentPath)..add(entry.key),
      ));
    }
    return currentMap;
  }
  if (body is List<dynamic>) {
    for (var i = 0; i < body.length; i++) {
      currentMap.addAll(_extractFlattenedFileMap(
        body[i],
        currentMap: currentMap,
        currentPath: List<String>.from(currentPath)..add(i.toString()),
      ));
    }
    return currentMap;
  }

  if (body is http.MultipartFile) {
    return currentMap
      ..addAll({
        currentPath.join('.'): body,
      });
  }

  return currentMap;
}
