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

`graphql_flutter` provides an idiomatic flutter API and widgets for [`graphql/client.dart`](https://pub.dev/packages/graphql). They are co-developed [on github](https://github.com/zino-app/graphql-flutter), where you can find more in-depth examples. We also have a lively community on [discord][discord-link].

This guide is mostly focused on setup, widgets, and flutter-specific considerations. For more in-depth details on the `graphql` API, see the [`graphql` README](../graphql/README.md)

- [GraphQL Flutter](#graphql-flutter)
  - [Installation](#installation)
  - [Migration Guide](#migration-guide)
  - [Usage](#usage)
    - [GraphQL Provider](#graphql-provider)
    - [Query](#query)
      - [Fetch More (Pagination)](#fetch-more-pagination)
    - [Mutations](#mutations)
      - [Optimism](#optimism)
    - [Subscriptions](#subscriptions)
    - [GraphQL Consumer](#graphql-consumer)

**Useful sections in the [`graphql` README](../graphql/README.md):**

- [in-depth link guide](../graphql/README.md#links)
- [Direct Cache Access](../graphql/README.md#direct-cache-access-api)
- [Policies](../graphql/README.md#exceptions)
- [Exceptions](../graphql/README.md#exceptions)
- [AWS AppSync Support](../graphql/README.md#aws-appsync-support)
- [GraphQL Upload](../graphql/README.md#graphql-upload)
- [Parsing ASTs at build-time](../graphql/README.md#parsing-asts-at-build-time)


**Useful API Docs:**

- [`GraphQLCache`](https://pub.dev/documentation/graphql/4.0.0-alpha.11/graphql/GraphQLCache-class.html)
- [`GraphQLDataProxy` API docs](https://pub.dev/documentation/graphql/4.0.0-alpha.11/graphql/GraphQLDataProxy-class.html) (direct cache access)

## Installation

First, depend on this package:

```yaml
dependencies:
  graphql_flutter: ^4.0.0-beta
```

And then import it inside your dart code:

```dart
import 'package:graphql_flutter/graphql_flutter.dart';
```

## Migration Guide

Find the migration from version 3 to version 4 [here](./../../changelog-v3-v4.md).

## Usage

To connect to a GraphQL Server, we first need to create a `GraphQLClient`. A `GraphQLClient` requires both a `cache` and a `link` to be initialized.

In our example below, we will be using the Github Public API. we are going to use `HttpLink` which we will concatenate with `AuthLink` so as to attach our github access token. For the cache, we are going to use `GraphQLCache`.

```dart
...

import 'package:graphql_flutter/graphql_flutter.dart';

void main() async {

  // We're using HiveStore for persistence,
  // so we need to initialize Hive.
  await initHiveForFlutter();

  final HttpLink httpLink = HttpLink(
    'https://api.github.com/graphql',
  );

  final AuthLink authLink = AuthLink(
    getToken: () async => 'Bearer <YOUR_PERSONAL_ACCESS_TOKEN>',
    // OR
    // getToken: () => 'Bearer <YOUR_PERSONAL_ACCESS_TOKEN>',
  );

  final Link link = authLink.concat(httpLink);

  ValueNotifier<GraphQLClient> client = ValueNotifier(
    GraphQLClient(
      link: link,
      // The default store is the InMemoryStore, which does NOT persist to disk
      store: GraphQLCache(store: HiveStore()),
    ),
  );

  ...
}

...
```

### GraphQL Provider

In order to use the client, your `Query` and `Mutation` widgets must be wrapped with the `GraphQLProvider` widget.

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

### Query

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
    document: gql(readRepositories), // this is the query string you just created
    variables: {
      'nRepositories': 50,
    },
    pollInterval: Duration(seconds: 10),
  ),
  // Just like in apollo refetch() could be used to manually trigger a refetch
  // while fetchMore() can be used for pagination purpose
  builder: (QueryResult result, { VoidCallback refetch, FetchMore fetchMore }) {
    if (result.hasException) {
        return Text(result.exception.toString());
    }

    if (result.isLoading) {
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
    document: gql(addStar), // this is the mutation string you just created
    // you can update the cache based on results
    update: (GraphQLDataProxy cache, QueryResult result) {
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

`graphql` also provides [file upload](../graphql/README.md#graphql-upload) support as well.

#### Optimism

`GraphQLCache` allows for optimistic mutations by passing an `optimisticResult` to `RunMutation`. It will then call `update(GraphQLDataProxy cache, QueryResult result)` twice (once eagerly with `optimisticResult`), and rebroadcast all queries with the optimistic cache state.

A complete and well-commented rundown of how exactly one interfaces with the `proxy` provided to `update` can be fount in the
[`GraphQLDataProxy` API docs](https://pub.dev/documentation/graphql/4.0.0-alpha.11/graphql/GraphQLDataProxy-class.html)

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
// final Map<String, Object> repository;
// final bool optimistic;
// Map<String, Object> extractRepositoryData(Map<String, Object> data);
// Map<String, dynamic> get expectedResult;
Mutation(
  options: MutationOptions(
    document: gql(starred ? mutations.removeStar : mutations.addStar),
    update: (cache, result) {
      if (result.hasException) {
        print(result.exception);
      } else {
        final updated = {
          ...repository,
          ...extractRepositoryData(result.data),
        };
        cache.writeFragment(
          Fragment(
              document: gql(
            '''
              fragment fields on Repository {
                id
                name
                viewerHasStarred
              }
            ''',
            // helper for constructing FragmentRequest
          )).asRequest(idFields: {
            '__typename': updated['__typename'],
            'id': updated['id'],
          }),
          data: updated,
          broadcast: false,
        );
      }
    },
    onError: (OperationException error) { },
    onCompleted: (dynamic resultData) { },
  ),
  builder: (RunMutation toggleStar, QueryResult result) {
    return ListTile(
      leading: starred
          ? const Icon(
              Icons.star,
              color: Colors.amber,
            )
          : const Icon(Icons.star_border),
      trailing: result.isLoading || optimistic
          ? const CircularProgressIndicator()
          : null,
      title: Text(repository['name'] as String),
      onTap: () {
        toggleStar(
          {'starrableId': repository['id']},
          optimisticResult: expectedResult,
        );
      },
    );
  },
)
```

### Subscriptions

The syntax for subscriptions is again similar to a query, however, it utilizes WebSockets and dart Streams to provide real-time updates from a server.

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

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Subscription(
          options: SubscriptionOptions(
            document: subscriptionDocument,
          ),
          builder: (result) {
            if (result.hasException) {
              return Text(result.exception.toString());
            }

            if (result.isLoading) {
              return Center(
                child: const CircularProgressIndicator(),
              );
            }
            // ResultAccumulator is a provided helper widget for collating subscription results.
            // careful though! It is stateful and will discard your results if the state is disposed
            return ResultAccumulator.appendUniqueEntries(
              latest: result.data,
              builder: (context, {results}) => DisplayReviews(
                reviews: results.reversed.toList(),
              ),
            );
          }
        ),
      )
    );
  }
}
```

### GraphQL Consumer

If you want to use the `client` directly, say for some its
[direct cache update](https://pub.dev/documentation/graphql/4.0.0-alpha.11/graphql/GraphQLDataProxy-class.html) methods,
You can use `GraphQLConsumer` to grab it from any `context` descended from a `GraphQLProvider`:

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
