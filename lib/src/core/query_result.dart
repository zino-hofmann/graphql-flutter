import 'package:graphql_flutter/src/core/graphql_error.dart';

class QueryResult {
  /// List<dynamic> or Map<String, dynamic>
  dynamic data;
  List<GraphQLError> errors;
  bool loading;
  bool stale;

  QueryResult({
    this.data,
    this.errors,
    this.loading,
    this.stale,
  });

  bool get hasErrors {
    if (errors == null) {
      return false;
    }

    return errors.isNotEmpty;
  }

  void addError(GraphQLError graphQLError) {
    if (errors != null) {
      errors.add(graphQLError);
    } else {
      errors = <GraphQLError>[graphQLError];
    }
  }
}
