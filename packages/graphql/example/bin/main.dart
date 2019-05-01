import 'package:graphql/client.dart';
import './graphql_operation/queries/readRepositories.dart';
import 'package:args/args.dart';
import 'dart:io';

// to run the example, create a file ../local.dart with the content:
// const String YOUR_PERSONAL_ACCESS_TOKEN =
//    '<YOUR_PERSONAL_ACCESS_TOKEN>';
import './local.dart';

GraphQLClient client() {
  final HttpLink _httpLink = HttpLink(
    uri: 'https://api.github.com/graphql',
  );

  final AuthLink _authLink = AuthLink(
    getToken: () async => 'Bearer $YOUR_PERSONAL_ACCESS_TOKEN',
  );

  final Link _link = _authLink.concat(_httpLink as Link);

  return GraphQLClient(
    cache: InMemoryCache(),
    link: _link,
  );
}

void query() async {
  final GraphQLClient _client = client();

  const int nRepositories = 50;

  final QueryOptions options = QueryOptions(
    document: readRepositories,
    variables: <String, dynamic>{
      'nRepositories': nRepositories,
    },
  );

  final QueryResult result = await _client.query(options);

  if (result.hasErrors) {
    print(result.errors);
    return;
  }

  final List<dynamic> repositories =
      result.data['viewer']['repositories']['nodes'] as List<dynamic>;

  print(repositories);
  return;
}

void main(List<String> arguments) {
  query();
}
