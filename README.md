<div align="center">
  <h1>GraphQL Flutter</h1>

  <div align="center">
      <img src="https://miro.medium.com/max/1400/1*bU9k3XzmNAQ9F9J0uCiFsQ.png" width="800"/>
  </div>

  <p>
    <strong>A collection of packages to work with graphql server in dart and flutter.</strong>
  </p>

  <h4>
    <a href="https://github.com/zino-hofmann/graphql-flutter">Project Homepage</a>
  </h4>

  <a href="https://github.com/laanwj/rust-clightning-rpc/actions">
    <img alt="GitHub Workflow Status (branch)" src="https://img.shields.io/github/workflow/status/laanwj/rust-clightning-rpc/Integration%20testing/master?style=flat-square"/>
  </a>

  <a href="https://pub.dev/packages/graphql">
    <img alt="Pub Popularity" src="https://img.shields.io/pub/popularity/graphql?style=flat-square"/>
  </a>

  <a href="https://discord.gg/YBFCTXNbwY">
    <img alt="Discord" src="https://img.shields.io/discord/559455668810153989?style=flat-square"/>
  </a>

</div>

## Introduction

GraphQL brings many benefits, both to the client: devices will need fewer requests, and therefore reduce data usage. And to the programmer: requests are arguable, they have the same structure as the request.

This project combines the benefits of GraphQL with the benefits of `Streams` in Dart to deliver a high-performance client.

The project took inspiration from the [Apollo GraphQL client](https://github.com/apollographql/apollo-client), great work guys!

## Packages

This is a Monorepo which contains the following packages:

| Crate     | Description |  Version |
|:----------|:-----------:|--:|
| [graphql](./packages/graphql) | Client implementation to interact with any graphql server  | ![Pub Version (including pre-releases)](https://img.shields.io/pub/v/graphql?include_prereleases&style=flat-square)  |
| [graphql_flutter](./packages/graphql_flutter) | Flutter Widgets wrapper around graphql API | ![Pub Version (including pre-releases)](https://img.shields.io/pub/v/graphql_flutter?include_prereleases&style=flat-square) |

## Utils Tools

Around `graphql_flutter` are builds awesome tools like:

1. [graphql_flutter_bloc](https://github.com/artflutter/graphql_flutter_bloc)
2. [graphql_codegen](https://github.com/heftapp/graphql_codegen)

## Features
✅ &nbsp; Queries, Mutations, and Subscriptions  
✅ &nbsp; [Query polling and rebroadcasting](./packages/graphql/README.md#clientwatchquery-and-observablequery)  
✅ &nbsp; [In memory and persistent caching](./packages/graphql/README.md#persistence)  
✅ &nbsp; [GraphQL Upload](./packages/graphql/README.md#graphql-upload)  
✅ &nbsp; [Optimistic results](./packages/graphql_flutter/README.md#optimism)  
✅ &nbsp; [Modularity](./packages/graphql/README.md#links)  
✅ &nbsp; [Client-state management](./packages/graphql/README.md#direct-cache-access-api)  
⚠️  &nbsp; [Automatic Persisted Queries](./packages/graphql/README.md#persistedquerieslink-experimental-warning-out-of-service-warning) (out of service)  

## Contributing

Please see our [Hacking guide](./docs/dev/MAINTAINERS.md)

## Contributors

This package was originally created and published by the engineers at [Zino App BV](https://zinoapp.com). Since then the community has helped to make it even more useful for even more developers.

This project follows the [all-contributors](https://github.com/kentcdodds/all-contributors) specification. Contributions of any kind are welcome!

[build-status-badge]: https://img.shields.io/github/workflow/status/zino-hofmann/graphql-flutter/graphql-flutter%20Tests%20case?style=flat-square
[build-status-link]: https://github.com/zino-hofmann/graphql-flutter/actions
[coverage-badge]: https://img.shields.io/codecov/c/github/zino-hofmann/graphql-flutter/beta?style=flat-square
[coverage-link]: https://app.codecov.io/gh/zino-hofmann/graphql-flutter
[version-badge]: https://img.shields.io/pub/v/graphql_flutter.svg?style=flat-square
[package-link]: https://pub.dartlang.org/packages/graphql_flutter
[package-link-client]: https://pub.dartlang.org/packages/graphql
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

### Financial Contributors

Become a financial contributor and help us sustain our community. [[Contribute](https://opencollective.com/graphql-flutter/contribute)]

#### Individuals

<a href="https://opencollective.com/graphql-flutter"><img src="https://opencollective.com/graphql-flutter/individuals.svg?width=890"></a>

#### Organizations

Support this project with your organization. Your logo will show up here with a link to your website. [[Contribute](https://opencollective.com/graphql-flutter/contribute)]

<a href="https://opencollective.com/graphql-flutter/organization/0/website"><img src="https://opencollective.com/graphql-flutter/organization/0/avatar.svg"></a>
<a href="https://opencollective.com/graphql-flutter/organization/1/website"><img src="https://opencollective.com/graphql-flutter/organization/1/avatar.svg"></a>
<a href="https://opencollective.com/graphql-flutter/organization/2/website"><img src="https://opencollective.com/graphql-flutter/organization/2/avatar.svg"></a>
<a href="https://opencollective.com/graphql-flutter/organization/3/website"><img src="https://opencollective.com/graphql-flutter/organization/3/avatar.svg"></a>
<a href="https://opencollective.com/graphql-flutter/organization/4/website"><img src="https://opencollective.com/graphql-flutter/organization/4/avatar.svg"></a>
<a href="https://opencollective.com/graphql-flutter/organization/5/website"><img src="https://opencollective.com/graphql-flutter/organization/5/avatar.svg"></a>
<a href="https://opencollective.com/graphql-flutter/organization/6/website"><img src="https://opencollective.com/graphql-flutter/organization/6/avatar.svg"></a>
<a href="https://opencollective.com/graphql-flutter/organization/7/website"><img src="https://opencollective.com/graphql-flutter/organization/7/avatar.svg"></a>
<a href="https://opencollective.com/graphql-flutter/organization/8/website"><img src="https://opencollective.com/graphql-flutter/organization/8/avatar.svg"></a>
<a href="https://opencollective.com/graphql-flutter/organization/9/website"><img src="https://opencollective.com/graphql-flutter/organization/9/avatar.svg"></a>

## Articles and Videos

External guides, tutorials, and other resources from the GraphQL Flutter community

- [Ultimate toolchain to work with GraphQL in Flutter](https://medium.com/@v.ditsyak/ultimate-toolchain-to-work-with-graphql-in-flutter-13aef79c6484):  
  An intro to using `graphql_flutter` with [`artemis`](https://pub.dev/packages/artemis) for code generation and [`graphql-faker`](https://github.com/APIs-guru/graphql-faker) for API prototyping
