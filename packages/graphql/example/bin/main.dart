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


// mutation example - add star to repository
void starRepository(String repositoryID) async {
  if (repositoryID == "") {
    stderr.writeln("The ID of the Repository is Required!");
    exit(2);
  }

  final GraphQLClient _client = client();

  final MutationOptions options = MutationOptions(
    document: addStar,
    variables: <String, dynamic>{
      'starrableId': repositoryID,
    },
  );

  final QueryResult result = await _client.mutate(options);

  if (result.hasErrors) {
    stderr.writeln(result.errors);
    exit(2);
  }

  final bool isStarrred =
      result.data['action']['starrable']['viewerHasStarred'] as bool;

  if (isStarrred) {
    stdout.writeln('Thanks for your star!');
  }

  exit(0);
}

// mutation example - remove star from repository
void removeStarFromRepository(String repositoryID) async {
  if (repositoryID == "") {
    stderr.writeln("The ID of the Repository is Required!");
    exit(2);
  }

  final GraphQLClient _client = client();

  final MutationOptions options = MutationOptions(
    document: removeStar,
    variables: <String, dynamic>{
      'starrableId': repositoryID,
    },
  );

  final QueryResult result = await _client.mutate(options);

  if (result.hasErrors) {
    stderr.writeln(result.errors);
    exit(2);
  }

  final bool isStarrred =
      result.data['action']['starrable']['viewerHasStarred'] as bool;

  if (!isStarrred) {
    stdout.writeln('Sorry you changed your mind!');
  }

  exit(0);
}

void main(List<String> arguments) {
  query();
}
