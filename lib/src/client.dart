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

  Map<String, String> get headers =>
      {'Authorization': 'Bearer $apiToken', 'Content-Type': 'application/json'};

  // Methods
  Future execute({
    String query,
    Object variables,
  }) async {
    final requestBody = {
      'query': query,
      'variables': variables,
    };

    try {
      final res = await client.post(
        endPoint,
        headers: headers,
        body: json.encode(requestBody),
      );

      return _parseResponse(res);
    } catch (error) {
      throw error;
    }
  }

  Map _parseResponse(http.Response response) {
    final statusCode = response.statusCode;
    final reasonPhrase = response.reasonPhrase;

    if (statusCode < 200 || statusCode >= 400) {
      throw new http.ClientException(
          'Network Error: $statusCode $reasonPhrase');
    }

    final jsonResponse = json.decode(response.body);

    if (jsonResponse['errors'] != null) {
      throw new Exception(
          'Error returned by the server in the query' + jsonResponse['errors']);
    }

    return jsonResponse['data'];
  }
}
