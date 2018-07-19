# GraphQL Flutter

[![version][version-badge]][package]
[![MIT License][license-badge]][license]
[![All Contributors](https://img.shields.io/badge/all_contributors-5-orange.svg?style=flat-square)](#contributors)
[![PRs Welcome][prs-badge]](http://makeapullrequest.com)

[![Watch on GitHub][github-watch-badge]][github-watch]
[![Star on GitHub][github-star-badge]][github-star]

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
  - [Graphql Provider](#graphql-provider)
  - [Queries](#queries)
  - [Mutations](#mutations)
  - [Offline Cache](#offline-cache)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [Contributors](#contributors)

## Installation

First depend on the library by adding this to your packages `pubspec.yaml`:

```yaml
dependencies:
  graphql_flutter: ^0.5.4
```

Now inside your Dart code you can import it.

```dart
import 'package:graphql_flutter/graphql_flutter.dart';
```

## Usage

To use the client it first needs to be initialized with an endpoint and cache. If your endpoint requires authentication you can provide it to the client contructor. If you need to change the api token at a later stage, you can call the setter `apiToken` on the `Client` class.

> For this example we will use the public GitHub API.

```dart
...

import 'package:graphql_flutter/graphql_flutter.dart';

void main() {
  ValueNotifier<Client> client = new ValueNotifier(
    new Client(
      endPoint: 'https://api.github.com/graphql',
      cache: new InMemoryCache(),
      apiToken: '<YOUR_GITHUB_PERSONAL_ACCESS_TOKEN>',
    ),
  );

  ...
}

...
```

### Graphql Provider

In order to use the client, you app needs to be wrapped with the `GraphqlProvider` widget.

```dart
  ...

  return new GraphqlProvider(
    client: client,
    child: new MaterialApp(
      title: 'Flutter Demo',
      ...
    ),
  );

  ...
```

### Queries

Creating a query is as simple as creating a multiline string:

```dart
String readRepositories = """
  query ReadRepositories(\$nRepositories) {
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
"""
    .replaceAll('\n', ' ');
```

In your widget:

```dart
...

new Query(
  readRepositories, // this is the query you just created
  variables: {
    'nRepositories': 50,
  },
  pollInterval: 10, // optional
  builder: ({
    bool loading,
    var data,
    String error,
  }) {
    if (error != '') {
      return new Text(error);
    }

    if (loading) {
      return new Text('Loading');
    }

    // it can be either Map or List
    List repositories = data['viewer']['repositories']['nodes'];

    return new ListView.builder(
      itemCount: repositories.length,
      itemBuilder: (context, index) {
        final repository = repositories[index];

        return new Text(repository['name']);
    });
  },
);

...
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
"""
    .replaceAll('\n', ' ');
```

The syntax for mutations is fairly similar to that of a query. The only diffence is that the first argument of the builder function is a mutation function. Just call it to trigger the mutations (Yeah we deliberately stole this from react-apollo.)

```dart
...

new Mutation(
  addStar,
  builder: (
    runMutation, { // you can name it whatever you like
    bool loading,
    var data,
    String error,
}) {
  return new FloatingActionButton(
    onPressed: () => runMutation({
      'starrableId': <A_STARTABLE_REPOSITORY_ID>,
    }),
    tooltip: 'Star',
    child: new Icon(Icons.star),
  );
},
  onCompleted: (Map<String, dynamic> data) {
    showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Thanks for your star!'),
        actions: <Widget>[
          SimpleDialogOption(
            child: Text('Dismiss'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          )
        ],
      );
    }
  );
}),

...
```

### Offline Cache

The in-memory cache can automatically be saved to and restored from offline storage. Setting it up is as easy as wrapping your app with the `CacheProvider` widget.

> Make sure the `CacheProvider` widget is inside the `GraphqlProvider` widget.

```dart
...

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new GraphqlProvider(
      client: client,
      child: new CacheProvider(
        child: new MaterialApp(
          title: 'Flutter Demo',
          ...
        ),
      ),
    );
  }
}

...
```

## Roadmap

This is currently our roadmap, please feel free to request additions/changes.

| Feature                 | Progress |
| :---------------------- | :------: |
| Basic queries           |    ✅    |
| Basic mutations         |    ✅    |
| Basic subscriptions     |    🔜    |
| Query variables         |    ✅    |
| Mutation variables      |    ✅    |
| Subscription variables  |    🔜    |
| Query polling           |    ✅    |
| In memory caching       |    ✅    |
| Offline caching         |    ✅    |
| Optimistic results      |    🔜    |
| Client state management |    🔜    |

## Contributing

Feel free to open a PR with any suggestions! We'll be actively working on the library ourselves.

## Contributors

Thanks goes to these wonderful people ([emoji key](https://github.com/kentcdodds/all-contributors#emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore -->
| [<img src="https://avatars2.githubusercontent.com/u/4757453?v=4" width="100px;"/><br /><sub><b>Eustatiu Dima</b></sub>](http://eusdima.com)<br />[🐛](https://github.com/zino-app/graphql-flutter/issues?q=author%3Aeusdima "Bug reports") [💻](https://github.com/zino-app/graphql-flutter/commits?author=eusdima "Code") [📖](https://github.com/zino-app/graphql-flutter/commits?author=eusdima "Documentation") [💡](#example-eusdima "Examples") [🤔](#ideas-eusdima "Ideas, Planning, & Feedback") [👀](#review-eusdima "Reviewed Pull Requests") | [<img src="https://avatars3.githubusercontent.com/u/17142193?v=4" width="100px;"/><br /><sub><b>Zino Hofmann</b></sub>](https://github.com/HofmannZ)<br />[🐛](https://github.com/zino-app/graphql-flutter/issues?q=author%3AHofmannZ "Bug reports") [💻](https://github.com/zino-app/graphql-flutter/commits?author=HofmannZ "Code") [📖](https://github.com/zino-app/graphql-flutter/commits?author=HofmannZ "Documentation") [💡](#example-HofmannZ "Examples") [🤔](#ideas-HofmannZ "Ideas, Planning, & Feedback") [🚇](#infra-HofmannZ "Infrastructure (Hosting, Build-Tools, etc)") [👀](#review-HofmannZ "Reviewed Pull Requests") | [<img src="https://avatars2.githubusercontent.com/u/15068096?v=4" width="100px;"/><br /><sub><b>Harkirat Saluja</b></sub>](https://github.com/jinxac)<br />[📖](https://github.com/zino-app/graphql-flutter/commits?author=jinxac "Documentation") [🤔](#ideas-jinxac "Ideas, Planning, & Feedback") | [<img src="https://avatars3.githubusercontent.com/u/5178217?v=4" width="100px;"/><br /><sub><b>Chris Muthig</b></sub>](https://github.com/camuthig)<br />[💻](https://github.com/zino-app/graphql-flutter/commits?author=camuthig "Code") [📖](https://github.com/zino-app/graphql-flutter/commits?author=camuthig "Documentation") [💡](#example-camuthig "Examples") [🤔](#ideas-camuthig "Ideas, Planning, & Feedback") | [<img src="https://avatars1.githubusercontent.com/u/7611406?v=4" width="100px;"/><br /><sub><b>Cal Pratt</b></sub>](http://stackoverflow.com/users/3280538/flkes)<br />[🐛](https://github.com/zino-app/graphql-flutter/issues?q=author%3Acal-pratt "Bug reports") [💻](https://github.com/zino-app/graphql-flutter/commits?author=cal-pratt "Code") [📖](https://github.com/zino-app/graphql-flutter/commits?author=cal-pratt "Documentation") [💡](#example-cal-pratt "Examples") [🤔](#ideas-cal-pratt "Ideas, Planning, & Feedback") |
| :---: | :---: | :---: | :---: | :---: |

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/kentcdodds/all-contributors) specification. Contributions of any kind are welcome!

[version-badge]: https://img.shields.io/pub/v/graphql_flutter.svg?style=flat-square
[package]: https://pub.dartlang.org/packages/graphql_flutter
[license-badge]: https://img.shields.io/github/license/zino-app/graphql-flutter.svg?style=flat-square
[license]: https://github.com/zino-app/graphql-flutter/blob/master/LICENSE
[prs-badge]: https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square
[prs]: http://makeapullrequest.com
[github-watch-badge]: https://img.shields.io/github/watchers/zino-app/graphql-flutter.svg?style=social
[github-watch]: https://github.com/zino-app/graphql-flutter/watchers
[github-star-badge]: https://img.shields.io/github/stars/zino-app/graphql-flutter.svg?style=social
[github-star]: https://github.com/zino-app/graphql-flutter/stargazers
