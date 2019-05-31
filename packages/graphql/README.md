# GraphQL Client

[![Build Status][build-status-badge]][build-status-link]
[![Coverage][coverage-badge]][coverage-link]
[![version][version-badge]][package-link]
[![MIT License][license-badge]][license-link]
[![All Contributors](https://img.shields.io/badge/all_contributors-15-orange.svg)][contributors-link]
[![PRs Welcome][prs-badge]](http://makeapullrequest.com)

[![Watch on GitHub](https://img.shields.io/github/watchers/zino-app/graphql-flutter.svg?style=flat&logo=github&colorB=deeppink&label=Watchers)](https://github.com/felangel/bloc)
[![Star on GitHub](https://img.shields.io/github/stars/zino-app/graphql-flutter.svg?style=flat&logo=github&colorB=deeppink&label=Stars)](https://github.com/felangel/bloc)
[![Discord](https://img.shields.io/discord/559455668810153989.svg?label=&logo=discord&logoColor=ffffff&color=7389D8&labelColor=6A7EC2)](https://discord.gg/tXTtBfC)

## Installation 

First, depend on this package:

```yaml
dependencies:
  graphql: ^1.0.1-beta
```

And then import it inside your dart code:

```dart
import 'package:graphql/client.dart';
```

## Usage

To connect to a GraphQL Server, we first need to create a `GraphQLClient`. A `GraphQLClient` requires both a `cache` and a `link` to be initialized. 

In our example below, we will be using the Github Public API. In our example below, we are going to use `HttpLink` which we will concatinate with `AuthLink` so as to attach our github access token. For the cache, we are going to use `InMemoryCache`.

```dart
...

final HttpLink _httpLink = HttpLink(
    uri: 'https://api.github.com/graphql',
);

final AuthLink _authLink = AuthLink(
    getToken: () async => 'Bearer $YOUR_PERSONAL_ACCESS_TOKEN',
);

final Link _link = _authLink.concat(_httpLink as Link);

final GraphQLClient _client = GraphQLClient(
        cache: InMemoryCache(),
        link: _link,
    );

...

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

Then create a `QueryOptions` object with the query string as the document and pass any variables necessary. 

In our case, we need pass `nRepositories` variable and the document name is `readRepositories`. 

```dart

const int nRepositories = 50;

final QueryOptions options = QueryOptions(
    document: readRepositories,
    variables: <String, dynamic>{
        'nRepositories': nRepositories,
    },
);

```

And finally you can send the query to the server and `await` the response:

```dart
...

final QueryResult result = await _client.query(options);

if (result.hasErrors) {
    print(result.errors);
}

final List<dynamic> repositories =
    result.data['viewer']['repositories']['nodes'] as List<dynamic>;

...
```

### Mutations 

Creating a Matation is also similar to creating a query, with a small difference. First, start with a multiline string:

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
...

final MutationOptions options = MutationOptions(
  document: addStar,
  variables: <String, dynamic>{
    'starrableId': repositoryID,
  },
);

...
```

And finally you can send the query to the server and `await` the response:

```dart
...

final QueryResult result = await _client.mutate(options);

if (result.hasErrors) {
  print(result.errors);
  return;
}

final bool isStarrred =
    result.data['action']['starrable']['viewerHasStarred'] as bool;

if (isStarrred) {
  print('Thanks for your star!');
  return;
}

...
```

[build-status-badge]: https://circleci.com/gh/zino-app/graphql-flutter/tree/master.svg?style=svg
[build-status-link]: https://circleci.com/gh/zino-app/graphql-flutter/
[coverage-badge]: https://codecov.io/gh/zino-app/graphql-flutter/branch/master/graph/badge.svg
[coverage-link]: https://codecov.io/gh/zino-app/graphql-flutter
[version-badge]: https://img.shields.io/pub/v/graphql.svg
[package-link]: https://pub.dartlang.org/packages/graphql/versions/1.0.1-beta.4
[license-badge]: https://img.shields.io/github/license/zino-app/graphql-flutter.svg
[license-link]: https://github.com/zino-app/graphql-flutter/blob/master/LICENSE
[prs-badge]: https://img.shields.io/badge/PRs-welcome-brightgreen.svg
[prs]: http://makeapullrequest.com
[github-watch-badge]: https://img.shields.io/github/watchers/zino-app/graphql-flutter.svg?style=social
[github-watch]: https://github.com/zino-app/graphql-flutter/watchers
[github-star-badge]: https://img.shields.io/github/stars/zino-app/graphql-flutter.svg?style=social
[github-star]: https://github.com/zino-app/graphql-flutter/stargazers
[contributors-link]: https://github.com/zino-app/graphql-flutter#contributors
