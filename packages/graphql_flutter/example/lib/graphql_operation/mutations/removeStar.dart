const String removeStar = r'''
  mutation RemoveStar($starrableId: ID!) {
    action: removeStar(input: {starrableId: $starrableId}) {
      starrable {
        __typename
          id
        viewerHasStarred
      }
    }
  }
''';
