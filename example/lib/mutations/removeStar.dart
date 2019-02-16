const String removeStar = r'''
  mutation RemoveStar($starrableId: ID!) {
    action: removeStar(input: {starrableId: $starrableId}) {
      starrable {
        viewerHasStarred
      }
    }
  }
''';
