[![MIT License][license-badge]][license-link]
[![All Contributors](https://img.shields.io/badge/all_contributors-31-orange.svg?style=flat-square)](#contributors)
[![PRs Welcome][prs-badge]][prs-link]

[![Star on GitHub][github-star-badge]][github-star-link]
[![Watch on GitHub][github-watch-badge]][github-watch-link]
[![Discord][discord-badge]][discord-link]

[![Build Status][build-status-badge]][build-status-link]
[![Coverage][coverage-badge]][coverage-link]
[![version][version-badge]][package-link]

# GraphQL Client

[`graphql/client.dart`](https://pub.dev/packages/graphql) is a GraphQL client for dart modeled on the [apollo client], and is currently the most popular GraphQL client for dart. It is co-developed alongside [`graphql_flutter`](https://pub.dev/packages/graphql_flutter) [on github](https://github.com/zino-app/graphql-flutter), where you can find more in-depth examples. We also have a lively community alongside the rest of the GraphQL Dart community on [discord][discord-link].

As of `v4`, it is built on foundational libraries from the [gql-dart project], including [`gql`], [`gql_link`], and [`normalize`]. We also depend on [hive](https://docs.hivedb.dev/#/) for persistence via `HiveStore`.

- [GraphQL Client](#graphql-client)
  - [Installation](#installation)
  - [Migration Guide](#migration-guide)
  - [Basic Usage](#basic-usage)
    - [Persistence](#persistence)
    - [Options](#options)
    - [Query](#query)
    - [Mutations](#mutations)
      - [GraphQL Upload](#graphql-upload)
    - [Subscriptions](#subscriptions)
    - [`client.watchQuery` and `ObservableQuery`](#clientwatchquery-and-observablequery)
    - [`client.watchMutation`](#clientwatchmutation)
    - [Normalization](#normalization)
  - [Direct Cache Access API](#direct-cache-access-api)
    - [`Request`, `readQuery`, and `writeQuery`](#request-readquery-and-writequery)
    - [`FragmentRequest`, `readFragment`, and `writeFragment`](#fragmentrequest-readfragment-and-writefragment)
  - [Other Cache Considerations](#other-cache-considerations)
    - [Write strictness and `partialDataPolicy`](#write-strictness-and-partialdatapolicy)
    - [Possible cache write exceptions](#possible-cache-write-exceptions)
  - [Policies](#policies)
    - [Rebroadcasting](#rebroadcasting)
  - [Exceptions](#exceptions)
  - [Links](#links)
    - [Composing Links](#composing-links)
    - [AWS AppSync Support](#aws-appsync-support)
  - [Parsing ASTs at build-time](#parsing-asts-at-build-time)
  - [`PersistedQueriesLink` (experimental) :warning: OUT OF SERVICE :warning:](#persistedquerieslink-experimental-warning-out-of-service-warning)

**Useful API Docs:**

- [`GraphQLCache`](https://pub.dev/documentation/graphql/latest/graphql/GraphQLCache-class.html)
- [`GraphQLDataProxy` API docs](https://pub.dev/documentation/graphql/latest/graphql/GraphQLDataProxy-class.html) (direct cache access)

## Installation

First, depend on this package:

```yaml
dependencies:
  graphql: ^4.0.0-beta
```

And then import it inside your dart code:

```dart
import 'package:graphql/client.dart';
```

## Migration Guide

Find the migration from version 3 to version 4 [here](./../../changelog-v3-v4.md).

## Basic Usage

To connect to a GraphQL Server, we first need to create a `GraphQLClient`. A `GraphQLClient` requires both a `cache` and a `link` to be initialized.

In our example below, we will be using the Github Public API. we are going to use `HttpLink` which we will concatenate with `AuthLink` so as to attach our github access token.
For the cache, we are going to use `GraphQLCache`.

```dart
// ...

final _httpLink = HttpLink(
  'https://api.github.com/graphql',
);

final _authLink = AuthLink(
  getToken: () async => 'Bearer $YOUR_PERSONAL_ACCESS_TOKEN',
);

Link _link = _authLink.concat(_httpLink);

/// subscriptions must be split otherwise `HttpLink` will. swallow them
if (websocketEndpoint != null){
  final _wsLink = WebSocketLink(websockeEndpoint);
  _link = Link.split((request) => request.isSubscription, _wsLink, _link);
}

final GraphQLClient client = GraphQLClient(
  /// **NOTE** The default store is the InMemoryStore, which does NOT persist to disk
  cache: GraphQLCache(),
  link: _link,
);

// ...
```

### Persistence

In `v4`, `GraphQLCache` is decoupled from persistence, which is managed (or not) by its `store` argument.
We provide a `HiveStore` for easily using [hive](https://docs.hivedb.dev/#/) boxes as storage,
which requires a few changes to the above:

> **NB**: This is different in `graphql_flutter`, which provides `await initHiveForFlutter()` for initialization in `main`

```dart
GraphQL getClient() async {
  ...
  /// initialize Hive and wrap the default box in a HiveStore
  final store = await HiveStore.open(path: 'my/cache/path');
  return GraphQLClient(
      /// pass the store to the cache for persistence
      cache: GraphQLCache(store: store),
      link: _link,
  );
}
```

Once you have initialized a client, you can run queries and mutations.

### Options

All `graphql` methods accept a corresponding `*Options` object for configuring behavior. These options all include [policies](#policies) with which to override defaults, an `optimisticResult` for snappy client-side interactions, [`gql_exec` `Context`](https://github.com/gql-dart/gql/tree/master/links/gql_exec#context) with which to make requests, and of course a `document` to be requested.

Internally they are converted to [`gql_exec` `Requests`](https://github.com/gql-dart/gql/tree/master/links/gql_exec#context) with `.asRequest` for execution via [links](#links), and thus can also be used with the [direct cache access api](#direct-cache-access-api).

### Query

Creating a query is as simple as creating a multiline string:

```dart
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
```

Then create a `QueryOptions` object:

> **NB:** for `document` - Use our built-in help function - `gql(query)` to convert your document string to **ASTs** `document`.

In our case, we need to pass `nRepositories` variable and the document name is `readRepositories`.

```dart

const int nRepositories = 50;

final QueryOptions options = QueryOptions(
  document: gql(readRepositories),
  variables: <String, dynamic>{
    'nRepositories': nRepositories,
  },
);

```

And finally you can send the query to the server and `await` the response:

```dart
// ...

final QueryResult result = await client.query(options);

if (result.hasException) {
  print(result.exception.toString());
}

final List<dynamic> repositories =
    result.data['viewer']['repositories']['nodes'] as List<dynamic>;

// ...
```

### Mutations

Creating a mutation is similar to creating a query, with a small difference. First, start with a multiline string:

```dart
const String addStar = r'''
  mutation AddStar($starrableId: ID!) {
    action: addStar(input: {starrableId: $starrableId}) {
      starrable {
        viewerHasStarred
      }
    }
  }
''';
```

Then instead of the `QueryOptions`, for mutations we will `MutationOptions`, which is where we pass our mutation and id of the repository we are starring.

```dart
// ...

final MutationOptions options = MutationOptions(
  document: gql(addStar),
  variables: <String, dynamic>{
    'starrableId': repositoryID,
  },
);

// ...
```

And finally you can send the mutation to the server and `await` the response:

```dart
// ...

final QueryResult result = await client.mutate(options);

if (result.hasException) {
  print(result.exception.toString());
  return;
}

final bool isStarred =
    result.data['action']['starrable']['viewerHasStarred'] as bool;

if (isStarred) {
  print('Thanks for your star!');
  return;
}

// ...
```

#### GraphQL Upload

[gql_http_link](https://pub.dev/packages/gql_http_link) provides support for the GraphQL Upload spec as proposed at
https://github.com/jaydenseric/graphql-multipart-request-spec

```graphql
mutation($files: [Upload!]!) {
  multipleUpload(files: $files) {
    id
    filename
    mimetype
    path
  }
}
```

```dart
import "package:http/http.dart" show Multipartfile;

// ...

final myFile = MultipartFile.fromString(
  "",
  "just plain text",
  filename: "sample_upload.txt",
  contentType: MediaType("text", "plain"),
);

final result = await graphQLClient.mutate(
  MutationOptions(
    document: gql(uploadMutation),
    variables: {
      'files': [myFile],
    },
  )
);
```

### Subscriptions

To use subscriptions, a subscription-consuming link **must** be split from your `HttpLink` or other terminating link route:

```dart
link = Link.split((request) => request.isSubscription, websocketLink, link);
```

Then you can `subscribe` to any `subscription`s provided by your server schema:

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
subscription.listen(reactToAddedReview)
```

#### Customizing WebSocket Connections

`WebSocketLink` now has an experimental `connect` parameter that can be
used to supply custom headers to an IO client, register custom listeners,
and extract the socket for other non-graphql features.

**Warning:** if you want to listen to the listen to the stream,
wrap your channel with our `GraphQLWebSocketChannel` using the `.forGraphQL()` helper:
```dart
connect: (url, protocols) {
   var channel = WebSocketChannel.connect(url, protocols: protocols)
   // without this line, our client won't be able to listen to stream events,
   // because you are already listening.
   channel = channel.forGraphQL();
   channel.stream.listen(myListener)
   return channel;
}
```

To supply custom headers to an IO client:
```dart
connect: (url, protocols) =>
  IOWebSocketChannel.connect(url, protocols: protocols, headers: myCustomHeaders)
```

### `client.watchQuery` and `ObservableQuery`

[`client.watchQuery`](https://pub.dev/documentation/graphql/latest/graphql/GraphQLClient/watchQuery.html)
can be used to execute both queries and mutations, then reactively listen to changes to the underlying data in the cache. 

```dart
final observableQuery = client.watchQuery(
  WatchQueryOptions(
    fetchResults: true,
    document: gql(
      r'''
      query HeroForEpisode($ep: Episode!) {
        hero(episode: $ep) {
          name
        }
      }
      ''',
    ),
    variables: {'ep': 'NEWHOPE'},
  ),
);

/// Listen to the stream of results. This will include:
/// * `options.optimisitcResult` if passed
/// * The result from the server (if `options.fetchPolicy` includes networking)
/// * rebroadcast results from edits to the cache
observableQuery.stream.listen((QueryResult result) {
  if (!result.isLoading && result.data != null) {
    if (result.hasException) {
      print(result.exception);
      return;
    }
    if (result.isLoading) {
      print('loading');
      return;
    }
    doSomethingWithMyQueryResult(myCustomParser(result.data));
  }
});
// ... cleanup:
observableQuery.close();
```

`ObservableQuery` is a bit of a kitchen sink for reactive operation logic – consider looking at the [API docs](https://pub.dev/documentation/graphql/latest/graphql/ObservableQuery-class.html) if you'd like to develop a deeper understanding.

### `client.watchMutation`

The default `CacheRereadPolicy` of `client.watchQuery` merges optimistic data from the cache into the result on every related cache change. This is great for queries, but [an undesirable default for mutations](https://github.com/zino-app/graphql-flutter/issues/774), as their results should not change due to subsequent mutations.

While eventually [we would like to decouple mutation and query logic](https://github.com/zino-app/graphql-flutter/issues/798), for now we have `client.watchMutation` (used in the `Mutation` widget of `graphql_flutter`) which has the default policy `CacheRereadPolicy.ignoreAll`. **Otherwise, its behavior is exactly the same.** It still takes `WatchQueryOptions` and returns `ObservableQuery`, and both methods can take either mutation or query documents. The `watchMutation` method should be thought of as a stop-gap.

See [Rebroadcasting](#rebroadcasting) for more details.

> **NB**: `watchQuery`, `watchMutation`, and `ObservableQuery` currently don't have a nice APIs for `update` `onCompleted` and `onError` callbacks,
> but you can have a look at how `graphql_flutter` registers them through
> [`onData`](https://pub.dev/documentation/graphql/latest/graphql/ObservableQuery/onData.html) in
> [`Mutation.runMutation`](https://pub.dev/documentation/graphql_flutter/latest/graphql_flutter/MutationState/runMutation.html).

### Normalization
The [`GraphQLCache`](https://pub.dev/documentation/graphql/latest/graphql/GraphQLCache-class.html) automatically normalizes data from the server, and heavily leverages the [`normalize`] library. Data IDs are pulled from each selection set and used as keys in the cache.
The [default approach](https://pub.dev/documentation/normalize/latest/utils/resolveDataId.html) is roughly:
```dart
String dataIdFromObject(Map<String, Object> data) {
  final typename = data['__typename'];
  if (typename == null) return null;

  final id = data['id'] ?? data['_id'];
  return id == null ? null : '$typename:$id';
}
```
To disable cache normalization entirely, you could pass `(data) => null`.
If you only cared about `nodeId`, you could pass `(data) => data['nodeId']`.

Here's a more detailed example where the system involved contains versioned entities you don't want to clobber:
```dart 
String customDataIdFromObject(Map<String, Object> data) {
    final typeName = data['__typename'];
    final entityId = data['entityId'];
    final version = data['version'];
    if (typeName == null || entityId == null || version == null){
      return null;
    }
    return '${typeName}/${entityId}/${version}';
}
```

## Direct Cache Access API

The [`GraphQLCache`](https://pub.dev/documentation/graphql/latest/graphql/GraphQLCache-class.html)
leverages [`normalize`] to give us a fairly apollo-ish [direct cache access] API, which is also available on `GraphQLClient`.
This means we can do [local state management] in a similar fashion as well.

The cache access methods are available on any cache proxy, which includes the `GraphQLCache` the `OptimisticProxy` passed to `update` in the `graphql_flutter` `Mutation` widget, and the `client` itself.  
> **NB** counter-intuitively, you likely never want to use use direct cache access methods directly on the `cache`,
> as they will not be rebroadcast automatically.  
> **Prefer `client.writeQuery` and `client.writeFragment` to those on the `client.cache` for automatic rebroadcasting**

In addition to this overview, a complete and well-commented rundown of can be found in the
[`GraphQLDataProxy` API docs](https://pub.dev/documentation/graphql/latest/graphql/GraphQLDataProxy-class.html).

### `Request`, `readQuery`, and `writeQuery`

The query-based direct cache access methods `readQuery` and `writeQuery` leverage [`gql_exec` `Requests`](https://github.com/gql-dart/gql/tree/master/links/gql_exec#request) used internally in the link system. These can be retrieved from `options.asRequest` available on all `*Options` objects, or constructed manually:

```dart
const int nRepositories = 50;

final QueryOptions options = QueryOptions(
  document: gql(readRepositories),
  variables: {
    'nRepositories': nRepositories,
  },
);

var queryRequest = Request(
  operation: Operation(
    document: gql(readRepositories),
  ),
  variables: {
    'nRepositories': nRepositories,
  },
);

/// experimental convenience api
queryRequest = Operation(document: gql(readRepositories)).asRequest(
  variables: {
    'nRepositories': nRepositories,
  },
);

print(queryRequest == options.asRequest);

final data = client.readQuery(queryRequest);
client.writeQuery(queryRequest, data);
```

The cache access methods are available on any cache proxy, which includes the `GraphQLCache` the `OptimisticProxy` passed to `update` in the `graphql_flutter` `Mutation` widget, and the `client` itself.  
> **NB** counter-intuitively, you likely never want to use use direct cache access methods on the cache 
cache.readQuery(queryRequest);
client.readQuery(queryRequest); // 

### `FragmentRequest`, `readFragment`, and `writeFragment`
`FragmentRequest` has almost the same api as `Request`, but is provided directly from `graphql` for consistency.
It is used to access `readFragment` and `writeFragment`. The main differences are that they cannot be retreived from options, and that `FragmentRequests` require `idFields` to find their cooresponding entities:
```dart

final fragmentDoc = gql(
  r'''
    fragment mySmallSubset on MyType {
      myField,
      someNewField
    }
  ''',
);

var fragmentRequest = FragmentRequest(
  fragment: Fragment(
    document: fragmentDoc,
  ),
  idFields: {'__typename': 'MyType', 'id': 1},
);

/// same as experimental convenience api
fragmentRequest = Fragment(document: fragmentDoc).asRequest(
  idFields: {'__typename': 'MyType', 'id': 1},
);

final data = client.readFragment(fragmentRequest);
client.writeFragment(fragmentRequest, data);
```

> **NB** You likely want to call the cache access API from your `client` for automatic broadcasting support.

## Other Cache Considerations

### Write strictness and `partialDataPolicy`

As of [#754](https://github.com/zino-app/graphql-flutter/pull/754) we can now enforce strict structural constraints on data written to the cache. This means that if the client receives structurally invalid data from the network or on `client.writeQuery`, it will throw an exception.

By default, optimistic data is excluded from these constraints for ease of use via `PartialDataCachePolicy.acceptForOptimisticData`, as it is easy to miss `__typename`, etc.
This behavior is configurable via `GraphQLCache.partialDataPolicy`, which can be set to `accept` for no constraints or `reject` for full constraints.

### Possible cache write exceptions

At link execution time, one of the following exceptions can be thrown:

* `CacheMisconfigurationException` if the structure seems like it should write properly, and is perhaps failing due to a `typePolicy`
* `UnexpectedResponseStructureException` if the server response looks malformed.
* `MismatchedDataStructureException` in the event of a malformed optimistic result (and `PartialDataCachePolicy.reject`).
* `CacheMissException` if write succeeds but `readQuery` then returns `null` (though **data will not be overwritten**)

</details>

## Policies

Policies are used to configure various aspects of a request process, and can be set on any `*Options` object:
```dart
// override policies for a single query
client.query(QueryOptions(
  // return result from network and save to cache.
  fetchPolicy: FetchPolicy.networkOnly,
  // ignore all GraphQL errors.
  errorPolicy: ErrorPolicy.ignore,
  // ignore cache data.
  cacheRereadPolicy: CacheRereadPolicy.ignore,
  // ... 
));
```
Defaults can also be overridden via `defaultPolices` on the client itself:
```dart
GraphQLClient(
 defaultPolicies: DefaultPolicies(
    // make watched mutations behave like watched queries.
    watchMutation: Policies(
      FetchPolicy.cacheAndNetwork,
      ErrorPolicy.none,
      CacheRereadPolicy.mergeOptimistic,
    ),
  ),
  // ... 
)
```

**[`FetchPolicy`](https://pub.dev/documentation/graphql/latest/graphql/FetchPolicy-class.html):** determines where the client may return a result from, and whether that result will be saved to the cache.  
Possible options:

- cacheFirst: return result from cache. Only fetch from network if cached result is not available.
- cacheAndNetwork: return result from cache first (if it exists), then return network result once it's available.
- cacheOnly: return result from cache if available, fail otherwise.
- noCache: return result from network, fail if network call doesn't succeed, don't save to cache.
- networkOnly: return result from network, fail if network call doesn't succeed, save to cache.

**[`ErrorPolicy`](https://pub.dev/documentation/graphql/latest/graphql/ErrorPolicy-class.html):** determines the level of events for errors in the execution result.  
Possible options:

- none (default): Any GraphQL Errors are treated the same as network errors and any data is ignored from the response.
- ignore: Ignore allows you to read any data that is returned alongside GraphQL Errors,
  but doesn't save the errors or report them to your UI.
- all: Using the all policy is the best way to notify your users of potential issues while still showing as much data as possible from your server.
  It saves both data and errors into the Apollo Cache so your UI can use them.

**CacheRereadPolicy** determines whether and how cache data will be merged into the final `QueryResult.data` before it is returned.
Possible options:
* mergeOptimistic: Merge relevant optimistic data from the cache before returning.
* ignoreOptimistic: Ignore optimistic data, but still allow for non-optimistic cache rebroadcasts
  **if applicable**.
* ignoreAll: Ignore all cache data besides the result, and never rebroadcast the result,
  even if the underlying cache data changes.

### Rebroadcasting
Rebroadcasting behavior only applies to `watchMutation` and `watchQuery`, which both return an `ObservableQuery`.
There is no rebroadcasting option for subscriptions, because it would be indistiguishable from the previous event in the stream.

Rebroadcasting is enabled unless either `FetchPolicy.noCache` or `CacheRereadPolicy.ignoreAll` are set,
and whether it considers optimistic results is controlled by the specific `CacheRereadPolicy`.

## Exceptions

If there were problems encountered during a query or mutation, the `QueryResult` will have an `OperationException` in the `exception` field:

```dart
/// Container for both [graphqlErrors] returned from the server
/// and any [linkException] that caused a failure.
class OperationException implements Exception {
  /// Any graphql errors returned from the operation
  List<GraphQLError> graphqlErrors = [];

  /// Errors encountered during execution such as network or cache errors
  LinkException linkException;
}
```

Example usage:

```dart
if (result.hasException) {
  if (result.exception.linkException is NetworkException) {
    // handle network issues, maybe
  }
  return Text(result.exception.toString())
}
```

## Links

`graphql` and `graphql_flutter` now use the [`gql_link`] system, re-exporting
[gql_http_link](https://pub.dev/packages/gql_http_link),
[gql_error_link](https://pub.dev/packages/gql_error_link),
[gql_dedupe_link](https://pub.dev/packages/gql_dedupe_link),
and the api from [gql_link](https://pub.dev/packages/gql_link),
as well as our own custom `WebSocketLink` and `AuthLink`.

This makes all link development coordinated across the ecosystem, so that we can leverage existing links like [gql_dio_link](https://pub.dev/packages/gql_dio_link), and all link-based clients benefit from new link development (such as [ferry](https://github.com/gql-dart/ferry)).

### Composing Links

> **NB**: `WebSocketLink` and other "terminating links" must be used with `split` when there are multiple terminating links.

The [`gql_link`] systm has a well-specified routing system:
![link diagram]

a rundown of the composition api:

```dart
// kitchen sink:
Link.from([
  // common links run before every request
  DedupeLink(), // dedupe requests
  ErrorLink(onException: reportClientException),
]).split( // split terminating links, or they will break
  (request) => request.isSubscription,
  MyCustomSubscriptionAuthLink().concat(
    WebSocketLink(mySubscriptionEndpoint),
  ), // MyCustomSubscriptionAuthLink is only applied to subscriptions
  AuthLink(getToken: httpAuthenticator).concat(
    HttpLink(myAppEndpoint),
  )
);
// adding links after here would be pointless, as they would never be accessed

/// both `Link.from` and `link.concat` can be used to chain links:
final Link _link = _authLink.concat(_httpLink);
final Link _link = Link.from([_authLink, _httpLink]);

/// `Link.split` and `link.split` route requests to the left or right based on some condition
/// for instance, if you do `authLink.concat(httpLink).concat(websocketLink)`,
/// `websocketLink` won't see any `subscriptions`
link = Link.split((request) => request.isSubscription, websocketLink, link);
```

When combining links, **it isimportant to note that**:

- Terminating links like `HttpLink` and `WebsocketLink` must come at the end of a route, and will not call links following them.
- Link order is very important. In `HttpLink(myEndpoint).concat(AuthLink(getToken: authenticate))`, the `AuthLink` will never be called.

### AWS AppSync Support

**Cognito Pools**

To use with an AppSync GraphQL API that is authorized with AWS Cognito User Pools, simply pass the JWT token for your Cognito user session in to the `AuthLink`:

```dart
// Where `session` is a CognitorUserSession
// from amazon_cognito_identity_dart_2
final token = session.getAccessToken().getJwtToken();

final AuthLink authLink = AuthLink(
  getToken: () => token,
);
```

See more: [Issue #209](https://github.com/zino-app/graphql-flutter/issues/209)

**Other Authorization Types**

API key, IAM, and Federated provider authorization could be accomplished through custom links, but it is not known to be supported. Anyone wanting to implement this can reference AWS' JS SDK `AuthLink` implementation.

- Making a custom link: [Comment on Issue 173](https://github.com/zino-app/graphql-flutter/issues/173#issuecomment-464435942)
- AWS JS SDK `auth-link.ts`: [aws-mobile-appsync-sdk-js:auth-link.ts](https://github.com/awslabs/aws-mobile-appsync-sdk-js/blob/master/packages/aws-appsync-auth-link/src/auth-link.ts)

## Parsing ASTs at build-time

All `document` arguments are `DocumentNode`s from `gql/ast`.
We supply a `gql` helper for parsing, them, but you can also
parse documents at build-time use `ast_builder` from
[`package:gql_code_gen`](https://pub.dev/packages/gql_code_gen):

```yaml
dev_dependencies:
  gql_code_gen: ^0.1.5
```

**`add_star.graphql`**:

```graphql
mutation AddStar($starrableId: ID!) {
  action: addStar(input: { starrableId: $starrableId }) {
    starrable {
      viewerHasStarred
    }
  }
}
```

```dart
import 'package:gql/add_star.ast.g.dart' as add_star;

// ...

final MutationOptions options = MutationOptions(
  document: add_star.document,
  variables: <String, dynamic>{
    'starrableId': repositoryID,
  },
);

// ...
```

## `PersistedQueriesLink` (experimental) :warning: OUT OF SERVICE :warning:

**NOTE**: There is [a PR](https://github.com/zino-app/graphql-flutter/pull/699) for migrating the `v3` `PersistedQueriesLink`, and it works, but requires more consideration. It will be fixed before `v4` `stable` is published

To improve performance you can make use of a concept introduced by [apollo] called [Automatic persisted queries] (or short "APQ") to send smaller requests and even enabled CDN caching for your GraphQL API.

**ATTENTION:** This also requires you to have a GraphQL server that supports APQ, like [Apollo's GraphQL Server] and will only work for queries (but not for mutations or subscriptions).

You can than use it simply by prepending a `PersistedQueriesLink` to your normal `HttpLink`:

```dart
final PersistedQueriesLink _apqLink = PersistedQueriesLink(
  // To enable GET queries for the first load to allow for CDN caching
  useGETForHashedQueries: true,
);

final HttpLink _httpLink = HttpLink(
  'https://api.url/graphql',
);

final Link _link = _apqLink.concat(_httpLink);
```

[build-status-badge]: https://img.shields.io/circleci/build/github/zino-app/graphql-flutter.svg?style=flat-square
[build-status-link]: https://circleci.com/gh/zino-app/graphql-flutter
[coverage-badge]: https://img.shields.io/codecov/c/github/zino-app/graphql-flutter.svg?style=flat-square
[coverage-link]: https://codecov.io/gh/zino-app/graphql-flutter
[version-badge]: https://img.shields.io/pub/v/graphql_flutter.svg?style=flat-square
[package-link]: https://pub.dartlang.org/packages/graphql/versions
[license-badge]: https://img.shields.io/github/license/zino-app/graphql-flutter.svg?style=flat-square
[license-link]: https://github.com/zino-app/graphql-flutter/blob/master/LICENSE
[prs-badge]: https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square
[prs-link]: http://makeapullrequest.com
[github-watch-badge]: https://img.shields.io/github/watchers/zino-app/graphql-flutter.svg?style=flat-square&logo=github&logoColor=ffffff
[github-watch-link]: https://github.com/zino-app/graphql-flutter/watchers
[github-star-badge]: https://img.shields.io/github/stars/zino-app/graphql-flutter.svg?style=flat-square&logo=github&logoColor=ffffff
[github-star-link]: https://github.com/zino-app/graphql-flutter/stargazers
[discord-badge]: https://img.shields.io/discord/559455668810153989.svg?style=flat-square&logo=discord&logoColor=ffffff
[discord-link]: https://discord.gg/tXTtBfC
[gql-dart project]: https://github.com/gql-dart
[`gql_link`]: https://github.com/gql-dart/gql/tree/master/links/gql_link
[link diagram]: https://raw.githubusercontent.com/gql-dart/gql/master/links/gql_link/assets/gql_link.svg
[`gql`]: https://github.com/gql-dart/gql/tree/master/gql
[`normalize`]: https://github.com/gql-dart/ferry/tree/master/normalize
[apollo]: https://www.apollographql.com/
[apollo client]: https://www.apollographql.com/docs/react/
[automatic persisted queries]: https://www.apollographql.com/docs/apollo-server/performance/apq/
[apollo's graphql server]: https://www.apollographql.com/docs/apollo-server/
[local state management]: https://www.apollographql.com/docs/tutorial/local-state/#update-local-data
[`typepolicies`]: https://www.apollographql.com/docs/react/caching/cache-configuration/#the-typepolicy-type
[direct cache access]: https://www.apollographql.com/docs/react/caching/cache-interaction/
