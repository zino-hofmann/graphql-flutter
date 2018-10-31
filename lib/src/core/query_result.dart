import 'package:graphql_flutter/src/core/graphql_error.dart';

class QueryResult {
  QueryResult({
    this.data,
    this.errors,
    this.loading,
    this.stale,
    this.optimistic = false,
  });

  /// List<dynamic> or Map<String, dynamic>
  dynamic data;
  List<GraphQLError> errors;
  bool loading;
  bool stale;
  bool optimistic;

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
