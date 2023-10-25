/// Example functions for calling the Github GraphQL API
///
/// ### Queries
/// * [readRepositories()]
///
/// ### Mutations:
/// * [starRepository(id)]
/// * [removeStarFromRepository(id)]
///
/// To run the example, create a file `lib/local.dart` with the content:
/// ```dart
/// const String YOUR_PERSONAL_ACCESS_TOKEN =
///    '<YOUR_PERSONAL_ACCESS_TOKEN>';
/// ```
import 'dart:io' show stdout, stderr, exit;
import 'package:graphql/client.dart';

// to run the example, replace <YOUR_PERSONAL_ACCESS_TOKEN> with your GitHub token in ./local.dart
import './local.dart';

/// Get an authenticated [GraphQLClient] for the github api
///
/// `graphql/client.dart` leverages the [gql_link][1] interface,
/// re-exporting [HttpLink], [WebsocketLink], [ErrorLink], and [DedupeLink],
/// in addition to the links we define ourselves (`AuthLink`)
///
/// [1]: https://pub.dev/packages/gql_link
GraphQLClient getGithubGraphQLClient() {
  final Link _link = HttpLink(
    'https://api.github.com/graphql',
    defaultHeaders: {
      'Authorization': 'Bearer $YOUR_PERSONAL_ACCESS_TOKEN',
    },
  );

  return GraphQLClient(
    cache: GraphQLCache(),
    link: _link,
  );
}

/// query example - fetch all your github repositories
void readRepositories() async {
  final GraphQLClient _client = getGithubGraphQLClient();

  const int nRepositories = 50;

  final QueryOptions options = QueryOptions(
    document: gql(
      r'''
        query ReadRepositories($nRepositories: Int!) {
          viewer {
            repositories(last: $nRepositories) {
              nodes {
                __typename
                id
                name
                viewerHasStarred
              }
            }
          }
        }
      ''',
    ),
    variables: {
      'nRepositories': nRepositories,
    },
  );

  final QueryResult result = await _client.query(options);

  if (result.hasException) {
    stderr.writeln(result.exception.toString());
    exit(2);
  }

  final List<dynamic> repositories =
      result.data!['viewer']['repositories']['nodes'] as List<dynamic>;

  repositories.forEach(
    (dynamic f) => stdout.writeln('Id: ${f['id']} Name: ${f['name']}'),
  );

  exit(0);
}

// mutation example - add star to repository
void starRepository(String? repositoryID) async {
  if (repositoryID == '') {
    stderr.writeln('The ID of the Repository is Required!');
    exit(2);
  }

  final GraphQLClient _client = getGithubGraphQLClient();

  final options = MutationOptions(
    document: gql(
      r'''
        mutation AddStar($starrableId: ID!) {
          action: addStar(input: {starrableId: $starrableId}) {
            starrable {
              viewerHasStarred
            }
          }
        }
      ''',
    ),
    variables: <String, dynamic>{
      'starrableId': repositoryID,
    },
  );

  final QueryResult result = await _client.mutate(options);

  if (result.hasException) {
    stderr.writeln(result.exception.toString());
    exit(2);
  }

  final bool isStarrred =
      result.data!['action']['starrable']['viewerHasStarred'] as bool;

  if (isStarrred) {
    stdout.writeln('Thanks for your star!');
  }

  exit(0);
}

// mutation example - remove star from repository
void removeStarFromRepository(String? repositoryID) async {
  if (repositoryID == '') {
    stderr.writeln('The ID of the Repository is Required!');
    exit(2);
  }

  final GraphQLClient _client = getGithubGraphQLClient();

  final MutationOptions options = MutationOptions(
    document: gql(
      r'''
        mutation RemoveStar($starrableId: ID!) {
          action: removeStar(input: {starrableId: $starrableId}) {
            starrable {
              viewerHasStarred
            }
          }
        }
      ''',
    ),
    variables: <String, dynamic>{
      'starrableId': repositoryID,
    },
  );

  final QueryResult result = await _client.mutate(options);

  if (result.hasException) {
    stderr.writeln(result.exception.toString());
    exit(2);
  }

  final bool isStarrred =
      result.data!['action']['starrable']['viewerHasStarred'] as bool;

  if (!isStarrred) {
    stdout.writeln('Sorry you changed your mind!');
  }

  exit(0);
}
