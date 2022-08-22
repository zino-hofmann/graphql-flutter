/// Manage all the query supported by Amplify and used by the
/// mobile app.
class QueryManagerApp {
  /// Get the list of blogs that are stored in the backend
  ///
  /// As parameter the query want how many blogs do you want as result
  /// and the variable name is `limit`.
  static String listBlogs() {
    return r""" 
    query ListBlogs($limit: Int!){
      listBlogs(limit: $limit) {
        items {
          name
          createdAt
          posts(limit: 2) {
            items {
              title
              createdAt
            }
          }
        }
      }
    }
    """;
  }

  /// Subscribe to a new Blog and receive a new notification from server
  static String subscribeToNewBlog() {
    return r"""
   subscription MySubscription {
      onCreateBlog {
        id
        name
      }
    }
    """;
  }
}
