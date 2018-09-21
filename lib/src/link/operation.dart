import 'dart:convert';

class Operation {
  final String document;
  final Map<String, dynamic> variables;
  final String operationName;
  final Map<String, dynamic> extensions;

  final Map<String, dynamic> _context = <String, dynamic>{};

  Operation({
    this.document,
    this.variables,
    this.operationName,
    this.extensions,
  });

  /// Sets the context of an opration by merging the new context with the old one.
  void setContext(Map<String, dynamic> next) {
    _context.addAll(next);
  }

  Map<String, dynamic> getContext() {
    final Map<String, dynamic> result = <String, dynamic>{};
    result.addAll(_context);

    return result;
  }

  String toKey() {
    /// XXX we're assuming here that variables will be serialized in the same order.
    /// that might not always be true
    final String encodedVariables = json.encode(variables);

    return '$document|$encodedVariables|$operationName';
  }
}
