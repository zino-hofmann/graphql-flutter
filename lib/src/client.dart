import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import './cache/in_memory.dart';

Client client;

class Client {
  Client({
    String endPoint = '',
    String apiToken,
    InMemoryCache cache,
    Map<String, String> Function(Map<String, String>) handleHeaders,
    String Function(String) getAuthorizationHeader,
  }) {
    this.endPoint = endPoint;
    this.apiToken = apiToken;
    this.cache = cache;
    this.client = new http.Client();
    this._getAuthorizationHeader = getAuthorizationHeader;
  }

  String _endpoint;
  String _apiToken;
  InMemoryCache _cache;
  String Function(String) _getAuthorizationHeader;

  http.Client client;

  // Setters
  set endPoint(String value) {
    _endpoint = value;
  }

  set apiToken(String value) {
    _apiToken = value;
  }

  set cache(InMemoryCache cache) {
    _cache = cache;
  }

  set getAuthorizationHeader(String Function(String) value) {
    this._getAuthorizationHeader = value;
  }

  // Getters
  String get endPoint => this._endpoint;

  String get apiToken => this._apiToken;

  String Function(String) get getAuthorizationHeader => this._getAuthorizationHeader;

  Map<String, String> get headers {
    Map<String, String> headersMap = new Map();

    headersMap['Content-Type'] = 'application/json';

    if (apiToken != null) {
      headersMap['Authorization'] = 'Bearer $apiToken';

      if (getAuthorizationHeader is Function) {
        headersMap['Authorization'] = getAuthorizationHeader(apiToken);
      } else {
        headersMap['Authorization'] = 'Bearer $apiToken';
      }
    }

    return headersMap;
  }

  InMemoryCache get cache => this._cache;

  // Methods
  String _encodeBody(
    String query, {
    Map<String, dynamic> variables,
  }) {
    return json.encode({
      'query': query,
      'variables': variables,
    });
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    final int statusCode = response.statusCode;
    final String reasonPhrase = response.reasonPhrase;

    if (statusCode < 200 || statusCode >= 400) {
      throw new http.ClientException(
        'Network Error: $statusCode $reasonPhrase',
      );
    }

    final Map<String, dynamic> jsonResponse = json.decode(response.body);

    if (jsonResponse['errors'] != null) {
      throw new Exception(
        'Error returned by the server in the query' +
            jsonResponse['errors'].toString(),
      );
    }

    return jsonResponse['data'];
  }

  // The query method may send a request to your server if the appropriate data is not in your cache.
  Future<Map<String, dynamic>> query({
    String query,
    Map<String, dynamic> variables,
  }) async {
    final String body = _encodeBody(
      query,
      variables: variables,
    );

    try {
      final http.Response res = await client.post(
        endPoint,
        headers: headers,
        body: body,
      );

      final Map<String, dynamic> parsedResponse = _parseResponse(res);

      cache.write(body, parsedResponse);

      return parsedResponse;
    } catch (error) {
      throw error;
    }
  }

  // The readQuery method is very similar to the query method except that readQuery will never make a request to your GraphQL server.
  Map<String, dynamic> readQuery({
    String query,
    Map<String, dynamic> variables,
  }) {
    final String body = _encodeBody(
      query,
      variables: variables,
    );

    if (cache.hasEntity(body)) {
      return cache.read(body);
    } else {
      throw new Exception('Can\'t find field in cache.');
    }
  }
}
