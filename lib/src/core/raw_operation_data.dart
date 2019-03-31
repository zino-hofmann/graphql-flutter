import 'dart:collection' show SplayTreeMap;
import 'dart:convert' show json;
import 'dart:io' show File;

import 'package:meta/meta.dart';
import 'package:graphql_flutter/src/utilities/get_from_ast.dart'
    show getOperationName;

class RawOperationData {
  RawOperationData({
    @required this.document,
    Map<String, dynamic> variables,
    String operationName,
  })  : _operationName = operationName,
        this.variables = SplayTreeMap<String, dynamic>.of(
          variables ?? const <String, dynamic>{},
        );

  /// A GraphQL document that consists of a single query to be sent down to the server.
  String document;

  /// A map going from variable name to variable value, where the variables are used
  /// within the GraphQL query.
  Map<String, dynamic> variables;

  String _operationName;

  /// The last operation name appearing in the contained document.
  String get operationName {
    // XXX there is a bug in the `graphql_parser` package, where this result might be
    // null event though the operation name is present in the document
    _operationName ??= getOperationName(document);
    _operationName ??= 'UNNAMED/' + document.hashCode.toString();
    return _operationName;
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
