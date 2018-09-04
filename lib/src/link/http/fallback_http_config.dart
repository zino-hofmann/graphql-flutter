import 'package:graphql_flutter/src/link/http/http_config.dart';

HttpQueryOptions defaultHttpOptions = HttpQueryOptions(
  includeQuery: true,
  includeExtensions: false,
);

Map<String, dynamic> defaultOptions = <String, dynamic>{
  'method': 'POST',
};

Map<String, String> defaultHeaders = {
  'accept': '*/*',
  'content-type': 'application/json',
};

HttpConfig fallbackHttpConfig = HttpConfig(
  http: defaultHttpOptions,
  options: defaultOptions,
  headers: defaultHeaders,
);
