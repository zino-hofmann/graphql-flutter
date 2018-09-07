import 'package:meta/meta.dart';

class GraphQLRequest {
  final String query;
  Map<String, dynamic> variables;
  String operationName;
  Map<String, dynamic> context;
  Map<String, dynamic> extensions;

  GraphQLRequest({
    @required this.query,
    this.variables,
    this.operationName,
    this.context,
    this.extensions,
  });
}
