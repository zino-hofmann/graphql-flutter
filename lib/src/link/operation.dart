import 'package:meta/meta.dart';
import 'package:graphql_flutter/src/core/raw_operation_data.dart';

class Operation extends RawOperationData {
  Operation({
    @required String document,
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
    _context.addAll(next);
  }

  Map<String, dynamic> getContext() {
    final Map<String, dynamic> result = <String, dynamic>{};
    result.addAll(_context);

    return result;
  }

  // operationName should never be null, but leaving this check in anyways
  bool get isSubscription =>
      operationName != null &&
      document.contains(RegExp(r'.*?subscription ' + operationName));
}
