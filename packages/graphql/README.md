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

## Installation

First, depend on this package:

```yaml
dependencies:
  graphql: ^2.0.0
```

And then import it inside your dart code:

```dart
import 'package:graphql/client.dart';
```

### Parsing at build-time

To parse documents at build-time use `ast_builder` from
[`package:gql_code_gen`](https://pub.dev/packages/gql_code_gen):

```yaml
dev_dependencies:
  gql_code_gen: ^0.1.0
```

## Usage

To connect to a GraphQL Server, we first need to create a `GraphQLClient`. A `GraphQLClient` requires both a `cache` and a `link` to be initialized.

In our example below, we will be using the Github Public API. In our example below, we are going to use `HttpLink` which we will concatenate with `AuthLink` so as to attach our github access token. For the cache, we are going to use `InMemoryCache`.

```dart
// ...

final HttpLink _httpLink = HttpLink(
    uri: 'https://api.github.com/graphql',
);

final AuthLink _authLink = AuthLink(
    getToken: () async => 'Bearer $YOUR_PERSONAL_ACCESS_TOKEN',
);

final Link _link = _authLink.concat(_httpLink);

final GraphQLClient _client = GraphQLClient(
        cache: InMemoryCache(),
        link: _link,
    );

// ...

```

### Combining Multiple Links

#### Using Concat

```dart
final Link _link = _authLink.concat(_httpLink);
```

#### Using Links.from

`Link.from` joins multiple links into a single link at once.

```dart
final Link _link = Link.from([_authLink, _httpLink]);
```

Once you have initialized a client, you can run queries and mutations.

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

> **NB:** for `documentNode` - Use our built-in help function - `gql(query)` to convert your document string to **ASTs** `documentNode`.

In our case, we need to pass `nRepositories` variable and the document name is `readRepositories`.

```dart

const int nRepositories = 50;

final QueryOptions options = QueryOptions(
    documentNode: gql(readRepositories),
    variables: <String, dynamic>{
        'nRepositories': nRepositories,
    },
);

```

And finally you can send the query to the server and `await` the response:

```dart
// ...

final QueryResult result = await _client.query(options);

if (result.hasException) {
    print(result.exception.toString());
}

final List<dynamic> repositories =
    result.data['viewer']['repositories']['nodes'] as List<dynamic>;

// ...
```

### Mutations

Creating a Mutation is also similar to creating a query, with a small difference. First, start with a multiline string:

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
  documentNode: gql(addStar),
  variables: <String, dynamic>{
    'starrableId': repositoryID,
  },
);

// ...
```

And finally you can send the query to the server and `await` the response:

```dart
// ...

final QueryResult result = await _client.mutate(options);

if (result.hasException) {
    print(result.exception.toString());
    return
}

final bool isStarred =
    result.data['action']['starrable']['viewerHasStarred'] as bool;

if (isStarred) {
  print('Thanks for your star!');
  return;
}

// ...
```

### AST documents

> We are deprecating `document` and recommend you update your application to use
`documentNode` instead. `document` will be removed from the api in a future version.

For example:

```dart
// ...

final MutationOptions options = MutationOptions(
  documentNode: gql(addStar),
  variables: <String, dynamic>{
    'starrableId': repositoryID,
  },
);

// ...
```

With [`package:gql_code_gen`](https://pub.dev/packages/gql_code_gen) you can parse your `*.graphql` files at build-time.

**`add_star.graphql`**:

```graphql
mutation AddStar($starrableId: ID!) {
  action: addStar(input: {starrableId: $starrableId}) {
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
  documentNode: add_star.document,
  variables: <String, dynamic>{
    'starrableId': repositoryID,
  },
);

// ...
```

## Links

### `ErrorLink`

Perform custom logic when a GraphQL or network error happens, such as logging or
signing out.

```dart
final ErrorLink errorLink = ErrorLink(errorHandler: (ErrorResponse response) {
  Operation operation = response.operation;
  FetchResult result = response.fetchResult;
  OperationException exception = response.exception;
  print(exception.toString());
});
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
