import 'dart:collection' show SplayTreeMap;
import 'dart:convert' show json;
import 'dart:io' show File;

class Operation {
  factory Operation({
    String document,
    Map<String, dynamic> variables,
    String operationName,
    Map<String, dynamic> extensions,
  }) =>
      Operation._(
        document: document,
        variables: SplayTreeMap<String, dynamic>.of(variables),
        operationName: operationName,
        extensions: extensions,
      );

  Operation._({
    this.document,
    this.variables,
    this.operationName,
    this.extensions,
  });

  final String document;
  final SplayTreeMap<String, dynamic> variables;
  final String operationName;
  final Map<String, dynamic> extensions;

  final Map<String, dynamic> _context = <String, dynamic>{};

  /// Sets the context of an operation by merging the new context with the old one.
  void setContext(Map<String, dynamic> next) {
    _context.addAll(next);
  }

  Map<String, dynamic> getContext() {
    final Map<String, dynamic> result = <String, dynamic>{};
    result.addAll(_context);

    return result;
  }

  String toKey() {
    /// SplayTreeMap is always sorted
    final String encodedVariables =
        json.encode(variables, toEncodable: (dynamic object) {
      if (object is File) {
        return object.path;
      }
      return object;
    });

    return '$document|$encodedVariables|$operationName';
  }
}
