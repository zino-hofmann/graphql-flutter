[![MIT License][license-badge]][license-link]
[![All Contributors](https://img.shields.io/badge/all_contributors-31-orange.svg?style=flat-square)](#contributors)
[![PRs Welcome][prs-badge]][prs-link]

[![Star on GitHub][github-star-badge]][github-star-link]
[![Watch on GitHub][github-watch-badge]][github-watch-link]
[![Discord][discord-badge]][discord-link]

[![Build Status][build-status-badge]][build-status-link]
[![Coverage][coverage-badge]][coverage-link]
[![version][version-badge]][package-link]

# GraphQL Flutter

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
  - [GraphQL Provider](#graphql-provider)
  - [Offline Cache](#offline-cache)
    - [Normalization](#normalization)
    - [Optimism](#optimism)
  - [Queries](#queries)
    - [Fetch More (Pagination)](#fetch-more-pagination)
  - [Mutations](#mutations)
    - [Mutations with optimism](#mutations-with-optimism)
  - [Exceptions](#exceptions)
  - [Subscriptions (Experimental)](#subscriptions-experimental)
  - [GraphQL Consumer](#graphql-consumer)
  - [GraphQL Upload](#graphql-upload)
- [Roadmap](#roadmap)

## Installation

First, depends on the library by adding this to your packages `pubspec.yaml`:

```yaml
dependencies:
  graphql_flutter: ^2.0.0
```

Now inside your Dart code, you can import it.

```dart
import 'package:graphql_flutter/graphql_flutter.dart';
```

## Usage

To use the client it first needs to be initialized with a link and cache. For this example, we will be using an `HttpLink` as our link and `InMemoryCache` as our cache. If your endpoint requires authentication you can concatenate the `AuthLink`, it resolves the credentials using a future, so you can authenticate asynchronously.

> For this example we will use the public GitHub API.

```dart
...

import 'package:graphql_flutter/graphql_flutter.dart';

void main() {
  final HttpLink httpLink = HttpLink(
    uri: 'https://api.github.com/graphql',
  );

  final AuthLink authLink = AuthLink(
    getToken: () async => 'Bearer <YOUR_PERSONAL_ACCESS_TOKEN>',
    // OR
    // getToken: () => 'Bearer <YOUR_PERSONAL_ACCESS_TOKEN>',
  );

  final Link link = authLink.concat(httpLink);

  ValueNotifier<GraphQLClient> client = ValueNotifier(
    GraphQLClient(
      cache: InMemoryCache(),
      link: link,
    ),
  );

  ...
}

...
```

### GraphQL Provider

In order to use the client, you `Query` and `Mutation` widgets to be wrapped with the `GraphQLProvider` widget.

> We recommend wrapping your `MaterialApp` with the `GraphQLProvider` widget.

```dart
  ...

  return GraphQLProvider(
    client: client,
    child: MaterialApp(
      title: 'Flutter Demo',
      ...
    ),
  );

  ...
```

### Offline Cache

The in-memory cache can automatically be saved to and restored from offline storage. Setting it up is as easy as wrapping your app with the `CacheProvider` widget.

> It is required to place the `CacheProvider` widget is inside the `GraphQLProvider` widget, because `GraphQLProvider` makes client available through the build context.

```dart
...

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: client,
      child: CacheProvider(
        child: MaterialApp(
          title: 'Flutter Demo',
          ...
        ),
      ),
    );
  }
}

...
```

#### Normalization

To enable [apollo-like normalization](https://www.apollographql.com/docs/react/advanced/caching.html#normalization), use a `NormalizedInMemoryCache` or `OptimisticCache`:

```dart
ValueNotifier<GraphQLClient> client = ValueNotifier(
  GraphQLClient(
    cache: NormalizedInMemoryCache(
      dataIdFromObject: typenameDataIdFromObject,
    ),
    link: link,
  ),
);
```

`dataIdFromObject` is required and has no defaults. Our implementation is similar to Apollo's, requiring a function to return a universally unique string or `null`. The predefined `typenameDataIdFromObject` we provide is similar to apollo's default:

```dart
String typenameDataIdFromObject(Object object) {
  if (object is Map<String, Object> &&
      object.containsKey('__typename') &&
      object.containsKey('id')) {
    return "${object['__typename']}/${object['id']}";
  }
  return null;
}
```

However, note that **`graphql-flutter` does not inject \_\_typename into operations** the way Apollo does, so if you aren't careful to request them in your query, this normalization scheme is not possible.

Unlike Apollo, we don't have a real client-side document parser and resolver, so **operations leveraging normalization can have additional fields not specified in the query**. There are a couple of ideas for constraining this (leveraging `json_serializable`, or just implementing the resolver), but for now, the normalized cache uses a [`LazyCacheMap`](lib/src/cache/lazy_cache_map.dart), which wraps underlying data with a lazy denormalizer to allow for cyclical references. It has the same API as a normal `HashMap`, but is currently a bit hard to debug with, as a descriptive debug representation is currently unavailable.

NOTE: A `LazyCacheMap` can be modified, but this does not affect the underlying entities in the cache. If references are added to the map, they will still dereference against the cache normally.

#### Optimism

The `OptimisticCache` allows for optimistic mutations by passing an `optimisticResult` to `RunMutation`. It will then call `update(Cache cache, QueryResult result)` twice (once eagerly with `optimisticResult`), and rebroadcast all queries with the optimistic cache. You can tell which entities in the cache are optimistic through the `.isOptimistic` flag on `LazyCacheMap`, though note that **this is only the case for optimistic entities and not their containing operations/maps**.

`QueryResults` also, have an `optimistic` flag, but I would recommend looking at the data itself, as many situations make it unusable (such as toggling mutations like in the example below). [Mutation usage examples](#mutations-with-optimism)

### Queries

Creating a query is as simple as creating a multiline string:

```dart
String readRepositories = """
  query ReadRepositories(\$nRepositories: Int!) {
    viewer {
      repositories(last: \$nRepositories) {
        nodes {
          id
          name
          viewerHasStarred
        }
      }
    }
  }
""";
```

In your widget:

```dart
// ...
Query(
  options: QueryOptions(
    documentNode: gql(readRepositories), // this is the query string you just created
    variables: {
      'nRepositories': 50,
    },
    pollInterval: 10,
  ),
  // Just like in apollo refetch() could be used to manually trigger a refetch
  // while fetchMore() can be used for pagination purpose
  builder: (QueryResult result, { VoidCallback refetch, FetchMore fetchMore }) {
    if (result.hasException) {
        return Text(result.exception.toString());
    }

    if (result.loading) {
      return Text('Loading');
    }

    // it can be either Map or List
    List repositories = result.data['viewer']['repositories']['nodes'];

    return ListView.builder(
      itemCount: repositories.length,
      itemBuilder: (context, index) {
        final repository = repositories[index];

        return Text(repository['name']);
    });
  },
);
// ...
```

#### Fetch More (Pagination)

You can use `fetchMore()` function inside `Query` Builder to perform pagination. The `fetchMore()` function allows you to run an entirely new GraphQL operation and merge the new results with the original results. On top of that, you can re-use aspects of the Original query i.e. the Query or some of the Variables.

In order to use the `FetchMore()` function, you will need to first define `FetchMoreOptions` variable for the new query.

```dart
...
// this is returned by the GitHubs GraphQL API for pagination purpose
final Map pageInfo = result.data['search']['pageInfo'];
final String fetchMoreCursor = pageInfo['endCursor'];

FetchMoreOptions opts = FetchMoreOptions(
  variables: {'cursor': fetchMoreCursor},
  updateQuery: (previousResultData, fetchMoreResultData) {
    // this function will be called so as to combine both the original and fetchMore results
    // it allows you to combine them as you would like
    final List<dynamic> repos = [
      ...previousResultData['search']['nodes'] as List<dynamic>,
      ...fetchMoreResultData['search']['nodes'] as List<dynamic>
    ];

    // to avoid a lot of work, lets just update the list of repos in returned
    // data with new data, this also ensures we have the endCursor already set
    // correctly
    fetchMoreResultData['search']['nodes'] = repos;

    return fetchMoreResultData;
  },
);

...
```

And then, call the `fetchMore()` function and pass the `FetchMoreOptions` variable you defined above.

```dart
RaisedButton(
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Text("Load More"),
    ],
  ),
  onPressed: () {
    fetchMore(opts);
  },
)
```

### Mutations

Again first create a mutation string:

```dart
String addStar = """
  mutation AddStar(\$starrableId: ID!) {
    addStar(input: {starrableId: \$starrableId}) {
      starrable {
        viewerHasStarred
      }
    }
  }
""";
```

The syntax for mutations is fairly similar to that of a query. The only difference is that the first argument of the builder function is a mutation function. Just call it to trigger the mutations (Yeah we deliberately stole this from react-apollo.)

```dart
...

Mutation(
  options: MutationOptions(
    documentNode: gql(addStar), // this is the mutation string you just created
    // you can update the cache based on results
    update: (Cache cache, QueryResult result) {
      return cache;
    },
    // or do something with the result.data on completion
    onCompleted: (dynamic resultData) {
      print(resultData);
    },
  ),
  builder: (
    RunMutation runMutation,
    QueryResult result,
  ) {
    return FloatingActionButton(
      onPressed: () => runMutation({
        'starrableId': <A_STARTABLE_REPOSITORY_ID>,
      }),
      tooltip: 'Star',
      child: Icon(Icons.star),
    );
  },
);

...
```

#### Mutations with optimism

If you're using an [OptimisticCache](#optimism), you can provide an `optimisticResult`:

```dart
...
FlutterWidget(
  onTap: () {
    toggleStar(
      { 'starrableId': repository['id'] },
      optimisticResult: {
        'action': {
          'starrable': {'viewerHasStarred': !starred}
        }
      },
    );
  },
)
...
```

With a bit more context (taken from **[the complete mutation example `StarrableRepository`](example/lib/graphql_widget/main.dart)**):

```dart
// bool get starred => repository['viewerHasStarred'] as bool;
// bool get optimistic => (repository as LazyCacheMap).isOptimistic;
Mutation(
  options: MutationOptions(
    documentNode: gql(starred ? mutations.removeStar : mutations.addStar),
    // will be called for both optimistic and final results
    update: (Cache cache, QueryResult result) {
      if (result.hasException) {
        print(['optimistic', result.exception.toString()]);
      } else {
        final Map<String, Object> updated =
            Map<String, Object>.from(repository)
              ..addAll(extractRepositoryData(result.data));
        cache.write(typenameDataIdFromObject(updated), updated);
      }
    },
    // will only be called for final result
    onCompleted: (dynamic resultData) {
      showDialog<AlertDialog>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              extractRepositoryData(resultData)['viewerHasStarred'] as bool
                  ? 'Thanks for your star!'
                  : 'Sorry you changed your mind!',
            ),
            actions: <Widget>[
              SimpleDialogOption(
                child: const Text('Dismiss'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        },
      );
    },
  ),
  builder: (RunMutation toggleStar, QueryResult result) {
    return ListTile(
      leading: starred
          ? const Icon(
              Icons.star,
              color: Colors.amber,
            )
          : const Icon(Icons.star_border),
      trailing: result.loading || optimistic
          ? const CircularProgressIndicator()
          : null,
      title: Text(repository['name'] as String),
      onTap: () {
        toggleStar(
          { 'starrableId': repository['id'] },
          optimisticResult: {
            'action': {
              'starrable': {'viewerHasStarred': !starred}
            }
          },
        );
      },
    );
  },
);
```

### Exceptions

If there were problems encountered during a query or mutation, the `QueryResult` will have an `OperationException` in the `exception` field:

```dart
class OperationException implements Exception {
  /// Any graphql errors returned from the operation
  List<GraphQLError> graphqlErrors = [];

  /// Errors encountered during execution such as network or cache errors
  ClientException clientException;
}
```

Example usage:

```dart
if (result.hasException) {
    if (result.exception.clientException is NetworkException) {
        // handle network issues, maybe
    }
    return Text(result.exception.toString())
}
```

### Subscriptions (Experimental)

The syntax for subscriptions is again similar to a query, however, this utilizes WebSockets and dart Streams to provide real-time updates from a server.
Before subscriptions can be performed a global instance of `socketClient` needs to be initialized.

> We are working on moving this into the same `GraphQLProvider` structure as the http client. Therefore this api might change in the near future.

```dart
socketClient = await SocketClient.connect('ws://coolserver.com/graphql');
```

Once the `socketClient` has been initialized it can be used by the `Subscription` `Widget`

```dart
class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Subscription(
          operationName,
          query,
          variables: variables,
          builder: ({
            bool loading,
            dynamic payload,
            dynamic error,
          }) {
            if (payload != null) {
              return Text(payload['requestSubscription']['requestData']);
            } else {
              return Text('Data not found');
            }
          }
        ),
      )
    );
  }
}
```

### GraphQL Consumer

You can always access the client directly from the `GraphQLProvider` but to make it even easier you can also use them `GraphQLConsumer` widget.

```dart
  ...

  return GraphQLConsumer(
    builder: (GraphQLClient client) {
      // do something with the client

      return Container(
        child: Text('Hello world'),
      );
    },
  );

  ...
```

### GraphQL Upload

We support GraphQL Upload spec as proposed at
https://github.com/jaydenseric/graphql-multipart-request-spec

```grapql
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
import 'dart:io' show File;

// ...

String filePath = '/aboslute/path/to/file.ext';
final QueryResult r = await graphQLClientClient.mutate(
  MutationOptions(
    documentNode: gql(uploadMutation),
    variables: {
      'files': [File(filePath)],
    },
  )
);
```

## Roadmap

This is currently our roadmap, please feel free to request additions/changes.

| Feature                 | Progress |
| :---------------------- | :------: |
| Queries                 |    ✅    |
| Mutations               |    ✅    |
| Subscriptions           |    ✅    |
| Query polling           |    ✅    |
| In memory cache         |    ✅    |
| Offline cache sync      |    ✅    |
| GraphQL pload           |    ✅    |
| Optimistic results      |    ✅    |
| Client state management |    🔜    |
| Modularity              |    🔜    |

[build-status-badge]: https://img.shields.io/circleci/build/github/zino-app/graphql-flutter.svg?style=flat-square
[build-status-link]: https://circleci.com/gh/zino-app/graphql-flutter
[coverage-badge]: https://img.shields.io/codecov/c/github/zino-app/graphql-flutter.svg?style=flat-square
[coverage-link]: https://codecov.io/gh/zino-app/graphql-flutter
[version-badge]: https://img.shields.io/pub/v/graphql_flutter.svg?style=flat-square
[package-link]: https://pub.dartlang.org/packages/graphql_flutter
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
