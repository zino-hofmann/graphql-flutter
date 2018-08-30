import 'dart:convert';

class Operation {
  final String document;
  final Map<String, dynamic> variables;
  final String operationName;
  final Map<String, dynamic> extensions;

  Operation({
    this.document,
    this.variables,
    this.operationName,
    this.extensions,
  });

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

    return '$document|$encodedVariables|$operationName';
  }
}
