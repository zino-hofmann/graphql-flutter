import 'package:gql/ast.dart';

import 'package:graphql/src/core/raw_operation_data.dart';
import 'package:graphql/src/utilities/get_from_ast.dart';

class Operation extends RawOperationData {
  Operation({
    @Deprecated('The "document" option has been deprecated, use "documentNode" instead')
        String document,
    DocumentNode documentNode,
    Map<String, dynamic> variables,
    this.extensions,
    String operationName,
  }) : super(
            // ignore: deprecated_member_use_from_same_package
            document: document,
            documentNode: documentNode,
            variables: variables,
            operationName: operationName);

  factory Operation.fromOptions(RawOperationData options) {
    return Operation(
      documentNode: options.documentNode,
      variables: options.variables,
    );
  }

  final Map<String, dynamic> extensions;

  final Map<String, dynamic> _context = <String, dynamic>{};

  /// Sets the context of an operation by merging the new context with the old one.
  void setContext(Map<String, dynamic> next) {
    if (next != null) {
      _context.addAll(next);
    }
  }

  Map<String, dynamic> getContext() {
    final Map<String, dynamic> result = <String, dynamic>{};
    result.addAll(_context);

    return result;
  }

  bool get isSubscription => isOfType(
        OperationType.subscription,
        documentNode,
        operationName,
      );
}
