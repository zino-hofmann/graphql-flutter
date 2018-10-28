# GraphQL Flutter

[![version][version-badge]][package]
[![MIT License][license-badge]][license]
[![All Contributors](https://img.shields.io/badge/all_contributors-10-orange.svg?style=flat-square)](#contributors)
[![PRs Welcome][prs-badge]](http://makeapullrequest.com)

[![Watch on GitHub][github-watch-badge]][github-watch]
[![Star on GitHub][github-star-badge]][github-star]

## 🎉🥂🍾 Time to celebrate!

**We're currently working on version 1.0.0 and we'd recommend you check it out. We did break a couple things (on purpose), so be sure to check out the [upgrade guide](https://github.com/zino-app/graphql-flutter/tree/next#upgrading-from-0xx). Also feel free to help us out on the [next branch](https://github.com/zino-app/graphql-flutter/tree/next).**

## Table of Contents

- [About this project](#about-this-project)
- [Installation](#installation)
- [Usage](#usage)
  - [Graphql Provider](#graphql-provider)
  - [Queries](#queries)
  - [Mutations](#mutations)
  - [Subscriptions (Experimental)](#subscriptions-experimental)
  - [Graphql Consumer](#graphql-consumer)
  - [Offline Cache (Experimental)](#offline-cache-experimental)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [Contributors](#contributors)

## About this project

GraphQL brings many benefits, both to the client: devices will need less requests, and therefore reduce data useage. And to the programer: requests are arguable, they have the same structure as the request.

The team at Apollo did a great job implenting GraphQL in Swift, Java and Javascript. But unfortunately they're not planning to release a Dart implementation.

This project is filling the gap, bringing the GraphQL spec to yet another programming language. We plan to implement most functionality from the [Apollo GraphQL client](https://github.com/apollographql/apollo-client) and from most features the [React Apollo](https://github.com/apollographql/react-apollo) components into Dart and Flutter respectively.

With that being said, the project lives currently still inside one package. We plan to spilt up the project into multiple smaler packages in the near future, to follow Apollo's modules design.

## Installation

First depend on the library by adding this to your packages `pubspec.yaml`:

```yaml
dependencies:
  graphql_flutter: ^0.9.5
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
  ValueNotifier<Client> client = ValueNotifier(
    Client(
      endPoint: 'https://api.github.com/graphql',
      cache: InMemoryCache(),
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

  return GraphqlProvider(
    client: client,
    child: MaterialApp(
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

Query(
  readRepositories, // this is the query you just created
  variables: {
    'nRepositories': 50,
  },
  pollInterval: 10, // optional
  builder: ({
    bool loading,
    var data,
    Exception error,
  }) {
    if (error != null) {
      return Text(error.toString());
    }

    if (loading) {
      return Text('Loading');
    }

    // it can be either Map or List
    List repositories = data['viewer']['repositories']['nodes'];

    return ListView.builder(
      itemCount: repositories.length,
      itemBuilder: (context, index) {
        final repository = repositories[index];

        return Text(repository['name']);
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

Mutation(
  addStar,
  builder: (
    runMutation, { // you can name it whatever you like
    bool loading,
    var data,
    Exception error,
}) {
  return FloatingActionButton(
    onPressed: () => runMutation({
      'starrableId': <A_STARTABLE_REPOSITORY_ID>,
    }),
    tooltip: 'Star',
    child: Icon(Icons.star),
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

### Subscriptions (Experimental)

The syntax for subscriptions is again similar to a query, however, this utilizes WebSockets and dart Streams to provide real-time updates from a server.
Before subscriptions can be performed a global intance of `socketClient` needs to be initialized.

> We are working on moving this into the same `GraphqlProvider` stucture as the http client. Therefore this api might change in the near future.

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

Once the `socketClient` is initialized you could also use it without Flutter.

```dart
final String operationName = "SubscriptionQuery";
final String query = """subscription $operationName(\$requestId: String!) {
  requestSubscription(requestId: \$requestId) {
    requestData
  }
}""";
final dynamic variables = {
  'requestId': 'My Request',
};
socketClient
    .subscribe(SubscriptionRequest(operationName, query, variables))
    .listen(print);
```

### Graphql Consumer

You can always access the client direcly from the `GraphqlProvider` but to make it even easier you can also use the `GraphqlConsumer` widget.

```dart
  ...

  return GraphqlConsumer(
    builder: (Client client) {
      // do something with the client

      return Container(
        child: Text('Hello world'),
      );
    },
  );

  ...
```

### Offline Cache (Experimental)

The in-memory cache can automatically be saved to and restored from offline storage. Setting it up is as easy as wrapping your app with the `CacheProvider` widget.

> Make sure the `CacheProvider` widget is inside the `GraphqlProvider` widget.

```dart
...

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GraphqlProvider(
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
| Optimistic results      |    🔜    |
| Client state management |    🔜    |
| Modularity              |    🔜    |

## Contributing

Feel free to open a PR with any suggestions! We'll be actively working on the library ourselves.

## Contributors

This package was originally created and published by the engineers at [Zino App B.V.](https://zinoapp.com). Since then the community has helped to make it even more useful for even more developers.

Thanks goes to these wonderful people ([emoji key](https://github.com/kentcdodds/all-contributors#emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore -->
| [<img src="https://avatars2.githubusercontent.com/u/4757453?v=4" width="100px;"/><br /><sub><b>Eustatiu Dima</b></sub>](http://eusdima.com)<br />[🐛](https://github.com/zino-app/graphql-flutter/issues?q=author%3Aeusdima "Bug reports") [💻](https://github.com/zino-app/graphql-flutter/commits?author=eusdima "Code") [📖](https://github.com/zino-app/graphql-flutter/commits?author=eusdima "Documentation") [💡](#example-eusdima "Examples") [🤔](#ideas-eusdima "Ideas, Planning, & Feedback") [👀](#review-eusdima "Reviewed Pull Requests") | [<img src="https://avatars3.githubusercontent.com/u/17142193?v=4" width="100px;"/><br /><sub><b>Zino Hofmann</b></sub>](https://github.com/HofmannZ)<br />[🐛](https://github.com/zino-app/graphql-flutter/issues?q=author%3AHofmannZ "Bug reports") [💻](https://github.com/zino-app/graphql-flutter/commits?author=HofmannZ "Code") [📖](https://github.com/zino-app/graphql-flutter/commits?author=HofmannZ "Documentation") [💡](#example-HofmannZ "Examples") [🤔](#ideas-HofmannZ "Ideas, Planning, & Feedback") [🚇](#infra-HofmannZ "Infrastructure (Hosting, Build-Tools, etc)") [👀](#review-HofmannZ "Reviewed Pull Requests") | [<img src="https://avatars2.githubusercontent.com/u/15068096?v=4" width="100px;"/><br /><sub><b>Harkirat Saluja</b></sub>](https://github.com/jinxac)<br />[📖](https://github.com/zino-app/graphql-flutter/commits?author=jinxac "Documentation") [🤔](#ideas-jinxac "Ideas, Planning, & Feedback") | [<img src="https://avatars3.githubusercontent.com/u/5178217?v=4" width="100px;"/><br /><sub><b>Chris Muthig</b></sub>](https://github.com/camuthig)<br />[💻](https://github.com/zino-app/graphql-flutter/commits?author=camuthig "Code") [📖](https://github.com/zino-app/graphql-flutter/commits?author=camuthig "Documentation") [💡](#example-camuthig "Examples") [🤔](#ideas-camuthig "Ideas, Planning, & Feedback") | [<img src="https://avatars1.githubusercontent.com/u/7611406?v=4" width="100px;"/><br /><sub><b>Cal Pratt</b></sub>](http://stackoverflow.com/users/3280538/flkes)<br />[🐛](https://github.com/zino-app/graphql-flutter/issues?q=author%3Acal-pratt "Bug reports") [💻](https://github.com/zino-app/graphql-flutter/commits?author=cal-pratt "Code") [📖](https://github.com/zino-app/graphql-flutter/commits?author=cal-pratt "Documentation") [💡](#example-cal-pratt "Examples") [🤔](#ideas-cal-pratt "Ideas, Planning, & Feedback") | [<img src="https://avatars0.githubusercontent.com/u/9830761?v=4" width="100px;"/><br /><sub><b>Miroslav Valkovic-Madjer</b></sub>](http://madjer.info)<br />[💻](https://github.com/zino-app/graphql-flutter/commits?author=mmadjer "Code") | [<img src="https://avatars2.githubusercontent.com/u/4523129?v=4" width="100px;"/><br /><sub><b>Aleksandar Faraj</b></sub>](https://github.com/AleksandarFaraj)<br />[🐛](https://github.com/zino-app/graphql-flutter/issues?q=author%3AAleksandarFaraj "Bug reports") |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| [<img src="https://avatars0.githubusercontent.com/u/403029?v=4" width="100px;"/><br /><sub><b>Arnaud Delcasse</b></sub>](https://www.scity.coop)<br />[🐛](https://github.com/zino-app/graphql-flutter/issues?q=author%3Aadelcasse "Bug reports") [💻](https://github.com/zino-app/graphql-flutter/commits?author=adelcasse "Code") | [<img src="https://avatars0.githubusercontent.com/u/959931?v=4" width="100px;"/><br /><sub><b>Dustin Graham</b></sub>](https://github.com/dustin-graham)<br />[🐛](https://github.com/zino-app/graphql-flutter/issues?q=author%3Adustin-graham "Bug reports") [💻](https://github.com/zino-app/graphql-flutter/commits?author=dustin-graham "Code") | [<img src="https://avatars3.githubusercontent.com/u/1375034?v=4" width="100px;"/><br /><sub><b>Fábio Carneiro</b></sub>](https://github.com/fabiocarneiro)<br />[🐛](https://github.com/zino-app/graphql-flutter/issues?q=author%3Afabiocarneiro "Bug reports") |

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
