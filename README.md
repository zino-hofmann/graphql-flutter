# GraphQL Flutter

[![version][version-badge]][package]
[![MIT License][license-badge]][license]
[![All Contributors](https://img.shields.io/badge/all_contributors-15-orange.svg?style=flat-square)](#contributors)
[![PRs Welcome][prs-badge]](http://makeapullrequest.com)

[![Watch on GitHub][github-watch-badge]][github-watch]
[![Star on GitHub][github-star-badge]][github-star]

https://pub.dartlang.org/packages/graphql_flutter

## Usage

In `main.dart`:

```dart
...

import 'package:graphql_flutter/graphql_flutter.dart';

void main() async {
  client = new Client('<YOUR_ENDPOINT>');
  client.apiToken = '<YOUR_API_KEY>';

  ...
}

...
```

Now create a quiry:

```dart
String readAllPeople = """
  query ReadAllPeople {
    allPeople(first: 4) {
      people {
        id
        name
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
  queries.readAllPeople,
  variables: {},
  pollInterval: 10,
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

    // It can be either Map or List or Map
    List people = data['allPeople']['people'];

    return new ListView.builder(
      itemCount: people.length,
      itemBuilder: (context, index) {
        final item = people[index];

        return new Text(item['name']);
    });
  },
)

...
```

The StarWars API does not have mutations, but has the same syntax as a query where the first argument of the builder function is the mutation function. Just call it to trigger the mutations (Yeah we deliberetly stole this from react-apollo.)

```dart
...

new Mutation(
  '<YOUR_MUTATION_STRING>',
  builder: (
    runMutation, {
    bool loading,
    var data,
    String error,
}) {
  return new FloatingActionButton(
    onPressed: () => runMutation({
      <YOUR_PARAMETERS>
    }),
    tooltip: 'Increment',
    child: new Icon(Icons.edit),
  );
}),

...
```

## Contributing

Feel free to open a PR with any suggetions! We'll be actively working on the library ourselfs.

## Contributors

Thanks goes to these wonderful people ([emoji key](https://github.com/kentcdodds/all-contributors#emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore -->
| [<img src="https://avatars2.githubusercontent.com/u/4757453?v=4" width="100px;"/><br /><sub><b>Eustatiu Dima</b></sub>](http://eusdima.com)<br />[💻](https://github.com/zino-app/graphql-flutter/commits?author=eusdima "Code") [📖](https://github.com/zino-app/graphql-flutter/commits?author=eusdima "Documentation") [💡](#example-eusdima "Examples") [🤔](#ideas-eusdima "Ideas, Planning, & Feedback") | [<img src="https://avatars3.githubusercontent.com/u/17142193?v=4" width="100px;"/><br /><sub><b>Zino Hofmann</b></sub>](https://github.com/HofmannZ)<br />[💻](https://github.com/zino-app/graphql-flutter/commits?author=HofmannZ "Code") [📖](https://github.com/zino-app/graphql-flutter/commits?author=HofmannZ "Documentation") [💡](#example-HofmannZ "Examples") [🤔](#ideas-HofmannZ "Ideas, Planning, & Feedback") [👀](#review-HofmannZ "Reviewed Pull Requests") |
| :---: | :---: |

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/kentcdodds/all-contributors) specification. Contributions of any kind welcome!

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
