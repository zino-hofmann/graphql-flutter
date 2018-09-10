class HttpQueryOptions {
  bool includeQuery;
  bool includeExtensions;

  HttpQueryOptions({
    this.includeQuery,
    this.includeExtensions,
  });

  void addAll(HttpQueryOptions options) {
    if (options.includeQuery != null) {
      includeQuery = options.includeQuery;
    }

    if (options.includeExtensions != null) {
      includeExtensions = options.includeExtensions;
    }
  }
}

class HttpConfig {
  HttpQueryOptions http;
  Map<String, dynamic> options;
  Map<String, dynamic> credentials;
  Map<String, String> headers;

  HttpConfig({
    this.http,
    this.options,
    this.credentials,
    this.headers,
  });
}

class HttpOptionsAndBody {
  final Map<String, dynamic> options;
  final String body;

  HttpOptionsAndBody({this.options, this.body});
}
