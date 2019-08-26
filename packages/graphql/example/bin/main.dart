import 'dart:io' show stdout, stderr, exit;

import 'package:args/args.dart';
import 'package:graphql/client.dart';

import './graphql_operation/mutations/mutations.dart';
import './graphql_operation/queries/readRepositories.dart';

// to run the example, create a file ../local.dart with the content:
// const String YOUR_PERSONAL_ACCESS_TOKEN =
//    '<YOUR_PERSONAL_ACCESS_TOKEN>';
// ignore: uri_does_not_exist
import './local.dart';

ArgResults argResults;

// client - create a graphql client
GraphQLClient client() {
  final HttpLink _httpLink = HttpLink(
    uri: 'https://api.github.com/graphql',
  );

  final AuthLink _authLink = AuthLink(
    // ignore: undefined_identifier
    getToken: () async => 'Bearer $YOUR_PERSONAL_ACCESS_TOKEN',
  );

  final Link _link = _authLink.concat(_httpLink);

  return GraphQLClient(
    cache: InMemoryCache(),
    link: _link,
  );
}

// query example - fetch all your github repositories
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
    stderr.writeln(result.graphqlErrors);
    exit(2);
  }

  final List<dynamic> repositories =
      result.data['viewer']['repositories']['nodes'] as List<dynamic>;

  repositories.forEach(
      (dynamic f) => {stdout.writeln('Id: ${f['id']} Name: ${f['name']}')});

  exit(0);
}

// mutation example - add star to repository
void starRepository(String repositoryID) async {
  if (repositoryID == '') {
    stderr.writeln('The ID of the Repository is Required!');
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
    stderr.writeln(result.graphqlErrors);
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
  if (repositoryID == '') {
    stderr.writeln('The ID of the Repository is Required!');
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
    stderr.writeln(result.graphqlErrors);
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
  final ArgParser parser = ArgParser()
    ..addOption('action', abbr: 'a', defaultsTo: 'fetch')
    ..addOption('id', defaultsTo: '');

  argResults = parser.parse(arguments);

  final String action = argResults['action'] as String;
  final String id = argResults['id'] as String;

  switch (action) {
    case 'star':
      starRepository(id);
      break;
    case 'unstar':
      removeStarFromRepository(id);
      break;
    default:
      query();
      break;
  }
}
