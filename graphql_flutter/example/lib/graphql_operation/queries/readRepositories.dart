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

const String testSubscription = r'''
		subscription test {
	    deviceChanged(id: 2) {
        id
        name
      }
		}
''';
