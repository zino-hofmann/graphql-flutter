import 'dart:collection' show SplayTreeMap;
import 'dart:convert' show json;

import 'package:gql/ast.dart';
import 'package:graphql/src/utilities/get_from_ast.dart';
import 'package:meta/meta.dart';

class RawOperationData {
  RawOperationData({
    @required this.document,
    Map<String, dynamic> variables,
    String operationName,
  })  : _operationName = operationName,
        variables = SplayTreeMap<String, dynamic>.of(
          variables ?? const <String, dynamic>{},
        );

  /// A GraphQL document that consists of a single query to be sent down to the server.
  DocumentNode document;

  /// A map going from variable name to variable value, where the variables are used
  /// within the GraphQL query.
  Map<String, dynamic> variables;

  String _operationName;

  /// The last operation name appearing in the contained document.
  String get operationName {
    _operationName ??= getLastOperationName(document);
    return _operationName;
  }

  String _documentIdentifier;

  /// The client identifier for this operation,
  // TODO remove $document from key? A bit redundant, though that's not the worst thing
  String get _identifier {
    _documentIdentifier ??=
        operationName ?? 'UNNAMED/' + document.hashCode.toString();
    return _documentIdentifier;
  }

  String toKey() {
    /// SplayTreeMap is always sorted
    final String encodedVariables = json.encode(
      variables,
      toEncodable: (dynamic object) {
        // TODO: transparently handle multipart file without introducing package:http
        // default toEncodable behavior
        return object.toJson();
      },
    );

    // TODO: document is being depracated, find ways for generating key
    return '$document|$encodedVariables|$_identifier';
  }
}
