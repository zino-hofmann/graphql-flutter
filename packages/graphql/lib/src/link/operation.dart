import 'package:gql/ast.dart';
import 'package:graphql/src/core/raw_operation_data.dart';
import 'package:graphql/src/utilities/get_from_ast.dart' as ast_utils;
import 'package:meta/meta.dart';

class Operation extends RawOperationData {
  Operation({
    @required DocumentNode document,
    Map<String, dynamic> variables,
    this.extensions,
    String operationName,
  }) : super(
            document: document,
            variables: variables,
            operationName: operationName);

  factory Operation.fromOptions(RawOperationData options) {
    return Operation(
      document: options.document,
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

  bool get isSubscription => ast_utils.isSubscription(document);
}
