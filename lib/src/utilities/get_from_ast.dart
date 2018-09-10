import 'package:graphql_parser/graphql_parser.dart';

String getOperationName(String rawDoc) {
  final List<Token> tokens = scan(rawDoc);
  final Parser parser = Parser(tokens);

  if (parser.errors.isNotEmpty) {
    // Handle errors...
    print(parser.errors.toString());
  }

  // Parse the GraphQL document using recursive descent
  final DocumentContext doc = parser.parseDocument();

  if (doc.definitions != null) {
    final OperationDefinitionContext definition = doc.definitions[0];

    if (definition != null) {
      if (definition.name != null) {
        return definition.name.runtimeType == OperationDefinitionContext
            ? definition.name
            : null;
      }
    }
  }

  return null;
}
