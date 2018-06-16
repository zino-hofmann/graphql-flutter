String readRepositories = """
  query ReadRepositories {
    viewer {
      repositories(last: 50) {
        nodes {
          id
          name
          viewerHasStarred
        }
      }
    }
  }
"""
    .replaceAll('\n', ' ');
