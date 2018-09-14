class FetchResult {
  List<dynamic> errors;

  /// List<dynamic> or Map<String, dynamic>
  dynamic data;
  Map<String, dynamic> extensions;
  Map<String, dynamic> context;

  FetchResult({
    this.errors,
    this.data,
    this.extensions,
    this.context,
  });
}
