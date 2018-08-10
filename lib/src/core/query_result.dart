class QueryResult {
  QueryResult({
    this.data,
    this.errors,
    this.loading,
    this.stale,
  });

  dynamic data; // List<Map<String, dynamic>> or Map<String, dynamic>
  List<Map<String, dynamic>> errors;
  bool loading;
  bool stale;
}
