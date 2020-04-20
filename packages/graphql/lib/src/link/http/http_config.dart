class HttpQueryOptions {
  HttpQueryOptions({
    this.includeQuery,
    this.includeExtensions,
    this.useGETForQueries,
  });

  bool includeQuery;
  bool includeExtensions;
  bool useGETForQueries;

  void addAll(HttpQueryOptions options) {
    if (options.includeQuery != null) {
      includeQuery = options.includeQuery;
    }

    if (options.includeExtensions != null) {
      includeExtensions = options.includeExtensions;
    }

    if (options.useGETForQueries != null) {
      useGETForQueries = options.useGETForQueries;
    }
  }
}

class HttpConfig {
  HttpConfig({
    this.http,
    this.options,
    this.credentials,
    this.headers,
  });

  HttpQueryOptions http;
  Map<String, dynamic> options;
  Map<String, dynamic> credentials;
  Map<String, String> headers;
}
