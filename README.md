[![MIT License][license-badge]][license-link]
[![Financial Contributors on Open Collective](https://opencollective.com/graphql-flutter/all/badge.svg?label=financial+contributors)](https://opencollective.com/graphql-flutter) [![All Contributors](https://img.shields.io/badge/all_contributors-31-orange.svg?style=flat-square)](#contributors)
[![PRs Welcome][prs-badge]][prs-link]

[![Star on GitHub][github-star-badge]][github-star-link]
[![Watch on GitHub][github-watch-badge]][github-watch-link]
[![Discord][discord-badge]][discord-link]

# GraphQL Flutter

## :mega: `v4` is now in `beta` :mega:

See the [Migration Guide](./changelog-v3-v4.md) and updated READMEs for details

## About this project

GraphQL brings many benefits, both to the client: devices will need fewer requests, and therefore reduce data usage. And to the programmer: requests are arguable, they have the same structure as the request.

This project combines the benefits of GraphQL with the benefits of `Streams` in Dart to deliver a high-performance client.

The project took inspiration from the [Apollo GraphQL client](https://github.com/apollographql/apollo-client), great work guys!

## Packages

[![Build Status][build-status-badge]][build-status-link]
[![Coverage][coverage-badge]][coverage-link]

This is a Monorepo which contains the following packages:

| Package                                       | Pub                                              |
| :-------------------------------------------- | :----------------------------------------------- |
| [graphql/client.dart](./packages/graphql)     | [![version][version-badge]][package-link-client] |
| [graphql_flutter](./packages/graphql_flutter) | [![version][version-badge]][package-link]        |

## Examples

Here are some examples you can follow:

1. [Starwars Example](./examples/starwars)
2. [`flutter_bloc` example](./examples/flutter_bloc)

## Articles and Videos

External guides, tutorials, and other resources from the GraphQL Flutter community

- [Ultimate toolchain to work with GraphQL in Flutter](https://medium.com/@v.ditsyak/ultimate-toolchain-to-work-with-graphql-in-flutter-13aef79c6484):  
  An intro to using `graphql_flutter` with [`artemis`](https://pub.dev/packages/artemis) for code generation and [`graphql-faker`](https://github.com/APIs-guru/graphql-faker) for API prototyping

## Roadmap

This is currently our roadmap, please feel free to request additions/changes.

| Feature                     | Progress |
| :-------------------------- | :------: |
| Queries                     |    ✅    |
| Mutations                   |    ✅    |
| Subscriptions               |    ✅    |
| Query polling               |    ✅    |
| In memory cache             |    ✅    |
| Offline cache sync          |    ✅    |
| GraphQL Upload              |    ✅    |
| Optimistic results          |    ✅    |
| Modularity                  |    ✅    |
| Automatic Persisted Queries |    ✅    |
| Client state management     |    ✅    |

## Contributing

To contribute, please see the [CONTRIBUTING.md](CONTRIBUTING.md) file.

## Contributors

This package was originally created and published by the engineers at [Zino App BV](https://zinoapp.com). Since then the community has helped to make it even more useful for even more developers.

Thanks goes to these wonderful people ([emoji key](https://github.com/kentcdodds/all-contributors#emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore -->
<table><tr><td align="center"><a href="http://eusdima.com"><img src="https://avatars2.githubusercontent.com/u/4757453?v=4" width="100px;" alt="Eustatiu Dima"/><br /><sub><b>Eustatiu Dima</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/issues?q=author%3Aeusdima" title="Bug reports">🐛</a> <a href="https://github.com/zino-app/graphql-flutter/commits?author=eusdima" title="Code">💻</a> <a href="https://github.com/zino-app/graphql-flutter/commits?author=eusdima" title="Documentation">📖</a> <a href="#example-eusdima" title="Examples">💡</a> <a href="#ideas-eusdima" title="Ideas, Planning, & Feedback">🤔</a> <a href="#review-eusdima" title="Reviewed Pull Requests">👀</a></td><td align="center"><a href="https://github.com/HofmannZ"><img src="https://avatars3.githubusercontent.com/u/17142193?v=4" width="100px;" alt="Zino Hofmann"/><br /><sub><b>Zino Hofmann</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/issues?q=author%3AHofmannZ" title="Bug reports">🐛</a> <a href="https://github.com/zino-app/graphql-flutter/commits?author=HofmannZ" title="Code">💻</a> <a href="https://github.com/zino-app/graphql-flutter/commits?author=HofmannZ" title="Documentation">📖</a> <a href="#example-HofmannZ" title="Examples">💡</a> <a href="#ideas-HofmannZ" title="Ideas, Planning, & Feedback">🤔</a> <a href="#infra-HofmannZ" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a> <a href="#review-HofmannZ" title="Reviewed Pull Requests">👀</a></td><td align="center"><a href="https://github.com/jinxac"><img src="https://avatars2.githubusercontent.com/u/15068096?v=4" width="100px;" alt="Harkirat Saluja"/><br /><sub><b>Harkirat Saluja</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/commits?author=jinxac" title="Documentation">📖</a> <a href="#ideas-jinxac" title="Ideas, Planning, & Feedback">🤔</a></td><td align="center"><a href="https://github.com/camuthig"><img src="https://avatars3.githubusercontent.com/u/5178217?v=4" width="100px;" alt="Chris Muthig"/><br /><sub><b>Chris Muthig</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/commits?author=camuthig" title="Code">💻</a> <a href="https://github.com/zino-app/graphql-flutter/commits?author=camuthig" title="Documentation">📖</a> <a href="#example-camuthig" title="Examples">💡</a> <a href="#ideas-camuthig" title="Ideas, Planning, & Feedback">🤔</a></td><td align="center"><a href="http://stackoverflow.com/users/3280538/flkes"><img src="https://avatars1.githubusercontent.com/u/7611406?v=4" width="100px;" alt="Cal Pratt"/><br /><sub><b>Cal Pratt</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/issues?q=author%3Acal-pratt" title="Bug reports">🐛</a> <a href="https://github.com/zino-app/graphql-flutter/commits?author=cal-pratt" title="Code">💻</a> <a href="https://github.com/zino-app/graphql-flutter/commits?author=cal-pratt" title="Documentation">📖</a> <a href="#example-cal-pratt" title="Examples">💡</a> <a href="#ideas-cal-pratt" title="Ideas, Planning, & Feedback">🤔</a></td><td align="center"><a href="http://madjer.info"><img src="https://avatars0.githubusercontent.com/u/9830761?v=4" width="100px;" alt="Miroslav Valkovic-Madjer"/><br /><sub><b>Miroslav Valkovic-Madjer</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/commits?author=mmadjer" title="Code">💻</a></td><td align="center"><a href="https://github.com/AleksandarFaraj"><img src="https://avatars2.githubusercontent.com/u/4523129?v=4" width="100px;" alt="Aleksandar Faraj"/><br /><sub><b>Aleksandar Faraj</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/issues?q=author%3AAleksandarFaraj" title="Bug reports">🐛</a></td></tr><tr><td align="center"><a href="https://www.scity.coop"><img src="https://avatars0.githubusercontent.com/u/403029?v=4" width="100px;" alt="Arnaud Delcasse"/><br /><sub><b>Arnaud Delcasse</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/issues?q=author%3Aadelcasse" title="Bug reports">🐛</a> <a href="https://github.com/zino-app/graphql-flutter/commits?author=adelcasse" title="Code">💻</a></td><td align="center"><a href="https://github.com/dustin-graham"><img src="https://avatars0.githubusercontent.com/u/959931?v=4" width="100px;" alt="Dustin Graham"/><br /><sub><b>Dustin Graham</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/issues?q=author%3Adustin-graham" title="Bug reports">🐛</a> <a href="https://github.com/zino-app/graphql-flutter/commits?author=dustin-graham" title="Code">💻</a></td><td align="center"><a href="https://github.com/fabiocarneiro"><img src="https://avatars3.githubusercontent.com/u/1375034?v=4" width="100px;" alt="Fábio Carneiro"/><br /><sub><b>Fábio Carneiro</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/issues?q=author%3Afabiocarneiro" title="Bug reports">🐛</a></td><td align="center"><a href="https://github.com/lordgreg"><img src="https://avatars0.githubusercontent.com/u/480546?v=4" width="100px;" alt="Gregor"/><br /><sub><b>Gregor</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/issues?q=author%3Alordgreg" title="Bug reports">🐛</a> <a href="https://github.com/zino-app/graphql-flutter/commits?author=lordgreg" title="Code">💻</a> <a href="#ideas-lordgreg" title="Ideas, Planning, & Feedback">🤔</a></td><td align="center"><a href="https://github.com/kolja-esders"><img src="https://avatars1.githubusercontent.com/u/5159563?v=4" width="100px;" alt="Kolja Esders"/><br /><sub><b>Kolja Esders</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/issues?q=author%3Akolja-esders" title="Bug reports">🐛</a> <a href="https://github.com/zino-app/graphql-flutter/commits?author=kolja-esders" title="Code">💻</a> <a href="#ideas-kolja-esders" title="Ideas, Planning, & Feedback">🤔</a></td><td align="center"><a href="https://github.com/micimize"><img src="https://avatars1.githubusercontent.com/u/8343799?v=4" width="100px;" alt="Michael Joseph Rosenthal"/><br /><sub><b>Michael Joseph Rosenthal</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/issues?q=author%3Amicimize" title="Bug reports">🐛</a> <a href="https://github.com/zino-app/graphql-flutter/commits?author=micimize" title="Code">💻</a> <a href="https://github.com/zino-app/graphql-flutter/commits?author=micimize" title="Documentation">📖</a> <a href="#example-micimize" title="Examples">💡</a> <a href="#ideas-micimize" title="Ideas, Planning, & Feedback">🤔</a> <a href="https://github.com/zino-app/graphql-flutter/commits?author=micimize" title="Tests">⚠️</a></td><td align="center"><a href="http://borges.me/"><img src="https://avatars2.githubusercontent.com/u/735858?v=4" width="100px;" alt="Igor Borges"/><br /><sub><b>Igor Borges</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/issues?q=author%3AIgor1201" title="Bug reports">🐛</a> <a href="https://github.com/zino-app/graphql-flutter/commits?author=Igor1201" title="Code">💻</a></td></tr><tr><td align="center"><a href="https://github.com/rafaelring"><img src="https://avatars1.githubusercontent.com/u/6992724?v=4" width="100px;" alt="Rafael Ring"/><br /><sub><b>Rafael Ring</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/issues?q=author%3Arafaelring" title="Bug reports">🐛</a> <a href="https://github.com/zino-app/graphql-flutter/commits?author=rafaelring" title="Code">💻</a></td><td align="center"><a href="http://truongsinh.pro"><img src="https://avatars0.githubusercontent.com/u/358585?v=4" width="100px;" alt="TruongSinh Tran-Nguyen"/><br /><sub><b>TruongSinh Tran-Nguyen</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/commits?author=truongsinh" title="Code">💻</a> <a href="#content-truongsinh" title="Content">🖋</a> <a href="https://github.com/zino-app/graphql-flutter/commits?author=truongsinh" title="Documentation">📖</a> <a href="#example-truongsinh" title="Examples">💡</a> <a href="#ideas-truongsinh" title="Ideas, Planning, & Feedback">🤔</a> <a href="#infra-truongsinh" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a> <a href="https://github.com/zino-app/graphql-flutter/commits?author=truongsinh" title="Tests">⚠️</a> <a href="#tutorial-truongsinh" title="Tutorials">✅</a></td><td align="center"><a href="https://codinglatte.com"><img src="https://avatars2.githubusercontent.com/u/12270550?v=4" width="100px;" alt="Maina Wycliffe"/><br /><sub><b>Maina Wycliffe</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/commits?author=mainawycliffe" title="Code">💻</a> <a href="https://github.com/zino-app/graphql-flutter/commits?author=mainawycliffe" title="Documentation">📖</a> <a href="#example-mainawycliffe" title="Examples">💡</a></td><td align="center"><a href="https://github.com/degroote22"><img src="https://avatars1.githubusercontent.com/u/12750442?v=4" width="100px;" alt="Lucas de Ávila Martins"/><br /><sub><b>Lucas de Ávila Martins</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/commits?author=degroote22" title="Code">💻</a></td><td align="center"><a href="https://github.com/szantogab"><img src="https://avatars1.githubusercontent.com/u/2809091?v=4" width="100px;" alt="szantogab"/><br /><sub><b>szantogab</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/commits?author=szantogab" title="Code">💻</a></td><td align="center"><a href="https://github.com/dbrb"><img src="https://avatars1.githubusercontent.com/u/1658994?v=4" width="100px;" alt="dbrb"/><br /><sub><b>dbrb</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/commits?author=dbrb" title="Code">💻</a></td><td align="center"><a href="https://yunyul.in/"><img src="https://avatars1.githubusercontent.com/u/8008350?v=4" width="100px;" alt="Yunyu Lin"/><br /><sub><b>Yunyu Lin</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/commits?author=yunyu" title="Code">💻</a></td></tr><tr><td align="center"><a href="https://zerosonessoftware.blogspot.com/"><img src="https://avatars2.githubusercontent.com/u/13663221?v=4" width="100px;" alt="Ammar Atef"/><br /><sub><b>Ammar Atef</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/commits?author=ammaratef45" title="Code">💻</a></td><td align="center"><a href="http://dev4mobile.blogspot.com"><img src="https://avatars1.githubusercontent.com/u/6807077?v=4" width="100px;" alt="Ariel Carbonaro"/><br /><sub><b>Ariel Carbonaro</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/commits?author=SirKuryaki" title="Code">💻</a></td><td align="center"><a href="https://github.com/ArneSchulze"><img src="https://avatars0.githubusercontent.com/u/32508820?v=4" width="100px;" alt="ArneSchulze"/><br /><sub><b>ArneSchulze</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/commits?author=ArneSchulze" title="Code">💻</a></td><td align="center"><a href="https://xtian.us"><img src="https://avatars0.githubusercontent.com/u/602654?v=4" width="100px;" alt="Christian Wesselhoeft"/><br /><sub><b>Christian Wesselhoeft</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/commits?author=xtian" title="Code">💻</a></td><td align="center"><a href="https://github.com/JarrodCColburn"><img src="https://avatars2.githubusercontent.com/u/16673615?v=4" width="100px;" alt="JarrodCColburn"/><br /><sub><b>JarrodCColburn</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/commits?author=JarrodCColburn" title="Code">💻</a></td><td align="center"><a href="http://mwalkerwells.com"><img src="https://avatars1.githubusercontent.com/u/16157429?v=4" width="100px;" alt="M. Walker Wells"/><br /><sub><b>M. Walker Wells</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/commits?author=mwalkerwells" title="Code">💻</a></td><td align="center"><a href="https://mateusfsilva.com"><img src="https://avatars0.githubusercontent.com/u/3394090?v=4" width="100px;" alt="Mateus Gustavo de Freitas e Silva"/><br /><sub><b>Mateus Gustavo de Freitas e Silva</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/commits?author=mateusfsilva" title="Code">💻</a></td></tr><tr><td align="center"><a href="https://github.com/pleopardi"><img src="https://avatars2.githubusercontent.com/u/22129342?v=4" width="100px;" alt="pleopardi"/><br /><sub><b>pleopardi</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/commits?author=pleopardi" title="Code">💻</a></td><td align="center"><a href="http://www.satkhalsa.com"><img src="https://avatars3.githubusercontent.com/u/6362903?v=4" width="100px;" alt="Sat Mandir S. Khalsa"/><br /><sub><b>Sat Mandir S. Khalsa</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/commits?author=smkhalsa" title="Code">💻</a></td><td align="center"><a href="https://www.youtube.com/c/NitishKumarSingh"><img src="https://avatars2.githubusercontent.com/u/15886737?v=4" width="100px;" alt="Nitish Kumar Singh"/><br /><sub><b>Nitish Kumar Singh</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/commits?author=nitishk72" title="Code">💻</a></td><td align="center"><a href="https://github.com/isacjunior"><img src="https://avatars0.githubusercontent.com/u/12630335?s=460&v=4" width="100px;" alt="Isac Junior"/><br /><sub><b>Isac Junior</b></sub></a><br /><a href="https://github.com/zino-app/graphql-flutter/commits?author=isacjunior" title="Code">💻</a></td></tr></table>

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/kentcdodds/all-contributors) specification. Contributions of any kind are welcome!

[build-status-badge]: https://img.shields.io/circleci/build/github/zino-app/graphql-flutter.svg?style=flat-square
[build-status-link]: https://circleci.com/gh/zino-app/graphql-flutter
[coverage-badge]: https://img.shields.io/codecov/c/github/zino-app/graphql-flutter.svg?style=flat-square
[coverage-link]: https://codecov.io/gh/zino-app/graphql-flutter
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

## Contributors

### Code Contributors

This project exists thanks to all the people who contribute. [[Contribute](CONTRIBUTING.md)].
<a href="https://github.com/zino-app/graphql-flutter/graphs/contributors"><img src="https://opencollective.com/graphql-flutter/contributors.svg?width=890&button=false" /></a>

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
