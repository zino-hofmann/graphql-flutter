import 'package:gql/ast.dart';
import 'package:gql/language.dart';

final DocumentNode readRepositories = parseString(r'''
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
''');

final DocumentNode searchRepositories = parseString(r'''
  query SearchRepositories($nRepositories: Int!, $query: String!, $cursor: String) {
    search(last: $nRepositories, query: $query, type: REPOSITORY, after: $cursor) {
      nodes {
        __typename
        ... on Repository {
          name
          shortDescriptionHTML
          viewerHasStarred
          stargazers {
            totalCount
          }
          forks {
            totalCount
          }
          updatedAt
        }
      }
      pageInfo {
        endCursor
        hasNextPage
      }
    }
  }
''');

final DocumentNode testSubscription = parseString(r'''
		subscription test {
	    deviceChanged(id: 2) {
        id
        name
      }
		}
''');
