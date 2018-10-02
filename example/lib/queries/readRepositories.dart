const String readRepositories = '''
  query ReadRepositories(\$numberOfRepos: Int!) {
    viewer {
      repositories(last: \$numberOfRepos) {
        nodes {
          id
          name
          viewerHasStarred
        }
      }
    }
  }
''';
