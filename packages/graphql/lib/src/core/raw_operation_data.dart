import 'dart:collection' show SplayTreeMap;
import 'dart:convert' show json;

import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:graphql/src/link/http/link_http_helper_deprecated_stub.dart'
    if (dart.library.io) 'package:graphql/src/link/http/link_http_helper_deprecated_io.dart';
import 'package:graphql/src/utilities/get_from_ast.dart';
import 'package:http/http.dart';

class RawOperationData {
  RawOperationData({
    @Deprecated('The "document" option has been deprecated, use "documentNode" instead')
        String document,
    DocumentNode documentNode,
    Map<String, dynamic> variables,
    String operationName,
  })  : assert(
          // ignore: deprecated_member_use_from_same_package
          document != null || documentNode != null,
          'Either a "document"  or "documentNode" option is required. '
          'You must specify your GraphQL document in the query options.',
        ),
        // todo: Investigate why this assertion is failing
        // assert(
        //   (document != null && documentNode == null) ||
        //       (document == null && documentNode != null),
        //   '"document" or "documentNode" options are mutually exclusive.',
        // ),
        // ignore: deprecated_member_use_from_same_package
        documentNode = documentNode ?? parseString(document),
        _operationName = operationName,
        variables = SplayTreeMap<String, dynamic>.of(
          variables ?? const <String, dynamic>{},
        );

  /// A GraphQL document that consists of a single query to be sent down to the server.
  DocumentNode documentNode;

  /// A string representation of [documentNode]
  @Deprecated(
    'The "document" option has been deprecated, use "documentNode" instead',
  )
  String get document => printNode(documentNode);

  @Deprecated(
    'The "document" option has been deprecated, use "documentNode" instead',
  )
  set document(value) {
    documentNode = parseString(value);
  }

  /// A map going from variable name to variable value, where the variables are used
  /// within the GraphQL query.
  Map<String, dynamic> variables;

  String _operationName;

  /// The last operation name appearing in the contained document.
  String get operationName {
    _operationName ??= getLastOperationName(documentNode);
    return _operationName;
  }

  String _documentIdentifier;

  /// The client identifier for this operation,
  // TODO remove $document from key? A bit redundant, though that's not the worst thing
  String get _identifier {
    _documentIdentifier ??=
        operationName ?? 'UNNAMED/' + documentNode.hashCode.toString();
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

    // TODO: document is being depracated, find ways for generating key
    // ignore: deprecated_member_use_from_same_package
    return '$document|$encodedVariables|$_identifier';
  }
}
