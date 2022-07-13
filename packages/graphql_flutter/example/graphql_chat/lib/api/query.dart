class Queries {
  static String getGetQuery() {
    return """
     query {
        getChats {
          __typename
          id
          description
          name
        }
      }
    """;
  }

  static String createChatMutation(
      {required String name, required String description}) {
    return """
      mutation {
        createChat(name: $name, description: $description) {
          id
          name
          description
        }
      }
    """;
  }

  static String subscribeToNewChat() {
    return """ 
    subscription {
      chatCreated {
        id
        name
        description
      }
    }
    """;
  }
}
