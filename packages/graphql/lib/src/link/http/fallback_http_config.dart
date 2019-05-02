import 'package:graphql/src/link/http/http_config.dart';

HttpQueryOptions defaultHttpOptions = HttpQueryOptions(
  includeQuery: true,
  includeExtensions: false,
);

Map<String, dynamic> defaultOptions = <String, dynamic>{
  'method': 'POST',
};

Map<String, String> defaultHeaders = <String, String>{
  'accept': '*/*',
  'content-type': 'application/json',
};

Map<String, dynamic> defaultCredentials = <String, dynamic>{};

HttpConfig fallbackHttpConfig = HttpConfig(
  http: defaultHttpOptions,
  options: defaultOptions,
  headers: defaultHeaders,
  credentials: defaultCredentials,
);
