# Migrating from v3 – v4

v4 aims to solve a number of sore spots, particularly with caching, largely by leveraging libraries from the https://github.com/gql-dart ecosystem. There has also been a concerted effort to add more API docstrings to the codebase.

## Cache overhaul

- There is now only a single `GraphQLCache`, which leverages [normalize](https://pub.dev/packages/normalize),
  Giving us a much more `apollo`ish api including `typePolicies`
- `LazyCacheMap` has been deleted
- `GraphQLCache` marks itself for rebroadcasting (should fix some related issues)
- **`Store`** is now a seperate concern:

```dart
GraphQLCache(
  // The default store is the InMemoryStore, which does NOT persist to disk
  store: await HiveStore.open(),
)
```

and persistence is broken into a seperate `Store` concern.

## We now use the [gql_link system](https://github.com/gql-dart/gql/tree/master/links/gql_link)

- Most links are re-exported from `graphql/client.dart`
- `QueryOptions`, `MutationOptions`, etc are turned into
  [gql_exec](https://github.com/gql-dart/gql/tree/master/links/gql_exec) `Request`s
  before being sent down the link chain.
- `documentNode` is deprecated in favor of `DocumentNode document` for consistency with `gql` libraries
- We won't leave alpha until we have [full backwards compatability](https://github.com/gql-dart/gql/issues/57)

```diff
final httpLink = HttpLink(
-  uri: 'https://api.github.com/graphql',
+  'https://api.github.com/graphql',
);

final authLink = AuthLink(
  getToken: () async => 'Bearer $YOUR_PERSONAL_ACCESS_TOKEN',
);

var link = authLink.concat(httpLink);

if (ENABLE_WEBSOCKETS) {
  final websocketLink = WebSocketLink(
-    uri: 'ws://localhost:8080/ws/graphql'
+    'ws://localhost:8080/ws/graphql'
  );

-  link = link.concat(websocketLink);
+  // split request based on type
+  link = Link.split(
+    (request) => request.isSubscription,
+    websocketLink,
+    link,
+  );
}
```

This makes all link development coordinated across the ecosystem, so that we can leverage existing links like [gql_dio_link](https://pub.dev/packages/gql_dio_link), and all link-based clients benefit from new link development

## `subscription` API overhaul

`Subscription`/`client.subscribe` API is in line with the rest of the API

```dart
final subscriptionDocument = gql(
  r'''
    subscription reviewAdded {
      reviewAdded {
        stars, commentary, episode
      }
    }
  ''',
);
// graphql/client.dart usage
subscription = client.subscribe(
  SubscriptionOptions(
    document: subscriptionDocument
  ),
);

// graphql_flutter/graphql_flutter.dart usage
Subscription(
  options: SubscriptionOptions(
    document: subscriptionDocument,
  ),
  builder: (result) { /*...*/ },
);
```

## Minor changes

- As mentioned before, `documentNode: gql(...)` is now `document: gql(...)`.
- The exported `gql` utility adds `__typename` automatically.
  \*\*If you define your own, make sure to include `AddTypenameVisitor`,
  or else that your cache `dataIdFromObject` works without it

### Enums are normalized and idiomatic

```diff
- QueryResultSource.OptimisticResult
+ QueryResultSource.optimisticResult
- QueryResultSource.Cache
+ QueryResultSource.cache
// etc

- QueryLifecycle.UNEXECUTED
+ QueryLifecycle.unexecuted
- QueryLifecycle.SIDE_EFFECTS_PENDING
+ QueryLifecycle.sideEffectsPending
```

### `client.fetchMore` (experimental)

The `fetchMore` logic is now available for when one isn't using `watchQuery`:

```dart
/// Untested example code
class MyQuery {
  QueryResult latestResult;
  QueryOptions initialOptions;

  FetchMoreOptions get _fetchMoreOptions {
    // resolve the fetchMore params based on some data in lastestResult,
    // like last item id or page number, and provide custom updateQuery logic
  }

  Future<QueryResult> fetchMore() async {
    final result = await client.fetchMore(
      _fetchMoreOptions,
      options: options,
      previousResult: latestResult,
    );
    _latestResult = result;
    return result;
  }
}
```
