import 'dart:convert';

class Operation {
  Operation({
    this.query,
    this.variables,
    this.operationName,
    this.extensions,
  });

  final String query;
  final Map<String, dynamic> variables;
  final String operationName;
  final Map<String, dynamic> extensions;

  Map<String, dynamic> _context = {};

  void setContext(Map<String, dynamic> next) {
    _context.addAll(next);
  }

  Map<String, dynamic> getContext() {
    Map<String, dynamic> result = {};
    result.addAll(_context);

    return result;
  }

  String toKey() {
    /// XXX we're assuming here that variables will be serialized in the same order.
    /// that might not always be true
    String encodedVariables = json.encode(variables);

    return '$query|$encodedVariables|$operationName';
  }
}

createOperation(Map<String, dynamic> graphqlRequest) {
  Map<String, dynamic> variables = {};
  Map<String, dynamic> extensions = {};

  if (graphqlRequest['variables'] != null) {
    variables.addAll(graphqlRequest['variables']);
  }

  if (graphqlRequest['extensions'] != null) {
    extensions.addAll(graphqlRequest['extensions']);
  }

  return new Operation(
    query: graphqlRequest['query'],
    variables: variables,
    operationName: graphqlRequest['operationName'],
    extensions: extensions,
  );
}
