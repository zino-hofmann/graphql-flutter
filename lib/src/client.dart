import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

Client client;

class Client {
  String _endpoint;
  String _apiToken;

  http.Client client;

  Client([String endPoint = ""]) {
    this.endPoint = endPoint;
    this.client = new http.Client();
  }

  // Setters
  set endPoint(String value) {
    _endpoint = value;
  }

  set apiToken(String value) {
    _apiToken = value;
  }

  // Getters
  String get endPoint => this._endpoint;

  String get apiToken => this._apiToken;

  Map<String, String> get headers => {
        'Authorization': 'Bearer $apiToken',
        'Content-Type': 'application/json',
      };

  // Methods
  Future<Map<String, dynamic>> execute({
    String query,
    Map<String, dynamic> variables,
  }) async {
    final Map<String, dynamic> requestBody = {
      'query': query,
      'variables': variables,
    };

    try {
      final http.Response res = await client.post(
        endPoint,
        headers: headers,
        body: json.encode(requestBody),
      );

      return _parseResponse(res);
    } catch (error) {
      throw error;
    }
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
        'Error returned by the server in the query' + jsonResponse['errors'],
      );
    }

    return jsonResponse['data'];
  }
}
