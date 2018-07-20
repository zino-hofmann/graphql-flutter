Map<String, bool> defaultHttpOptions = {
  'includeQuery': true,
  'includeExtensions': false,
};

Map<String, String> defaultHeaders = {
  'accept': '*/*',
  'content-type': 'application/json',
};

Map<String, String> defaultOptions = {
  'method': 'POST',
};

Map<String, Map<String, dynamic>> fallbackHttpConfig = {
  'http': defaultHttpOptions,
  'headers': defaultHeaders,
  'options': defaultOptions,
};
