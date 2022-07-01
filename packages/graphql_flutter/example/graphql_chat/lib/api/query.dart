class Queries {
  static String getGetQuery() {
    return """
     query {
        getChats {
          __typename
          id
          message
          name
        }
      }
    """;
  }

  static String createChatMutation({required String name, required String message}) {
    return """
      mutation {
        createChat(name: $name, message: $message) {
          id
          name
          message
        }
      }
    """;
  }
}