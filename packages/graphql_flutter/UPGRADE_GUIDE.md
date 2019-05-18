## Upgrading from 0.x.x

Here is a guide to fix most of the breaking changes introduced in 1.x.x.

Some class names have been renamed:

- Renamed `Client` to `GraphQLClient`
- Renamed `GraphqlProvider` to `GraphQLProvider`
- Renamed `GraphqlConsumer` to `GraphQLConsumer`
- Renamed `GQLError` to `GraphQLError`

We changed the way the client handles requests, it now uses a `Link` to execute queries rather than depend on the http package. We've currently only implemented the `HttpLink`, just drop it in like so:

```diff
void main() {
+  HttpLink link = HttpLink(
+    uri: 'https://api.github.com/graphql',
+    headers: <String, String>{
+      'Authorization': 'Bearer <YOUR_PERSONAL_ACCESS_TOKEN>',
+    },
+  );

-  ValueNotifier<Client> client = ValueNotifier(
+  ValueNotifier<GraphQLClient> client = ValueNotifier(
-  Client(
-    endPoint: 'https://api.github.com/graphql',
+  GraphQLClient(
      cache: InMemoryCache(),
-      apiToken: '<YOUR_GITHUB_PERSONAL_ACCESS_TOKEN>',
+      link: link,
    ),
  );
}
```

We have made a load of changes in how queries and mutations work under the hood. To allow for these changes we had to make some small changes to the API of the `Query` and `Mutation` widgets.

```diff
Query(
-  readRepositories,
+  options: QueryOptions(
+    document: readRepositories,
    variables: {
      'nRepositories': 50,
    },
    pollInterval: 10,
+  ),
-  builder: ({
-    bool loading,
-    var data,
-    String error,
-  }) {
+  builder: (QueryResult result, { VoidCallback refetch }) {
-    if (error != '') {
-      return Text(error);
+    if (result.errors != null) {
+      return Text(result.errors.toString());
    }

-    if (loading) {
+    if (result.loading) {
      return Text('Loading');
    }

-    List repositories = data['viewer']['repositories']['nodes'];
+    List repositories = result.data['viewer']['repositories']['nodes'];

    return ListView.builder(
      itemCount: repositories.length,
      itemBuilder: (context, index) {
        final repository = repositories[index];

        return Text(repository['name']);
    });
  },
);
```

```diff
Mutation(
-  addStar,
+  options: MutationOptions(
+    document: addStar,
+  ),
  builder: (
-    runMutation, {
-    bool loading,
-    var data,
-    String error,
+    RunMutation runMutation,
+    QueryResult result,
-  }) {
+  ) {
    return FloatingActionButton(
      onPressed: () => runMutation({
        'starrableId': <A_STARTABLE_REPOSITORY_ID>,
      }),
      tooltip: 'Star',
      child: Icon(Icons.star),
    );
  },
);
```

That's it! You should now be able to use the latest version of our library.

