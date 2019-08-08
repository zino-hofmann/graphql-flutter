const String readRepositories = r'''
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
''';

const String searchRepositories = r'''
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
''';

const String testSubscription = r'''
		subscription test {
	    deviceChanged(id: 2) {
        id
        name
      }
		}
''';
