import 'dart:collection' show SplayTreeMap;
import 'dart:convert' show json;

import 'package:http/http.dart';
import 'package:meta/meta.dart';

import 'package:graphql/src/utilities/get_from_ast.dart' show getOperationName;
import 'package:graphql/src/link/http/link_http_helper_deprecated_stub.dart'
    if (dart.library.io) 'package:graphql/src/link/http/link_http_helper_deprecated_io.dart';

class RawOperationData {
  RawOperationData({
    @required this.document,
    Map<String, dynamic> variables,
    String operationName,
  })  : assert(document != null),
        _operationName = operationName,
        variables = SplayTreeMap<String, dynamic>.of(
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
    final String encodedVariables =
        json.encode(variables, toEncodable: (dynamic object) {
      if (object is MultipartFile) {
        return object.filename;
      }
      // @deprecated, backward compatible only
      // in case the body is io.File
      // in future release, io.File will no longer be supported
      if (isIoFile(object)) {
        return object.path;
      }
      // default toEncodable behavior
      return object.toJson();
    });

    return '$document|$encodedVariables|$_identifier';
  }
}
