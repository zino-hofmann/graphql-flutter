import 'package:graphql_flutter/src/core/graphql_error.dart';

class QueryResult {
  dynamic data; // List<Map<String, dynamic>> or Map<String, dynamic>
  List<GraphQLError> errors;
  bool loading;
  bool stale;

  QueryResult({
    this.data,
    this.errors,
    this.loading,
    this.stale,
  });
}
