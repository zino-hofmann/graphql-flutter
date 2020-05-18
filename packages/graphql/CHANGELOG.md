## [3.0.2](https://github.com/zino-app/graphql-flutter/compare/v3.0.1...v3.0.2) (2020-05-18)


### Bug Fixes

* **client:** FetchMoreOptions bug with operator precedence ([f8e05af](https://github.com/zino-app/graphql-flutter/commit/f8e05af52f9720eed612f13b513d25f2456a8726))

## [3.0.1](https://github.com/zino-app/graphql-flutter/compare/v3.0.0...v3.0.1) (2020-04-20)


### Bug Fixes

* **style:** use curly braces ([42f4da4](https://github.com/zino-app/graphql-flutter/commit/42f4da4cb5ddb9f76c34a5946eb1bf662d138cbf))

# [3.0.0](https://github.com/zino-app/graphql-flutter/compare/v2.1.0...v3.0.0) (2020-01-13)


### Bug Fixes

* **cache:** add value == and hashCode to lazy cache map, fix traversal ([617dde7](https://github.com/zino-app/graphql-flutter/commit/617dde77e30505c9c85ba13570f40328e3b47d87))
* **cache:** AppLifecycleState.{suspending -> detached} ([8bc7b14](https://github.com/zino-app/graphql-flutter/commit/8bc7b14b182831c2df4824c661e3c87eaa66f78a))
* **ci:** attempt to fix ci ([4fac2e4](https://github.com/zino-app/graphql-flutter/commit/4fac2e422f0a868b1abfffdf94d3fe614ac7ca4f))
* **client:** default toEncodable ([5f938e4](https://github.com/zino-app/graphql-flutter/commit/5f938e4fa7691aa50bb07978bc547c0483833d90))
* **client:** export operation and fetch results ([5dcbae5](https://github.com/zino-app/graphql-flutter/commit/5dcbae5c410cb2f5d5775138ea9c77b66628d5aa))
* **client:** make fetchMore valid with default original document again ([faa3779](https://github.com/zino-app/graphql-flutter/commit/faa37791a309bd47405bf2d8a2902595eb62684e))
* **client:** organize exports alphabetically ([a322339](https://github.com/zino-app/graphql-flutter/commit/a3223394825ed07806359b9fd4b9b094597197bb))
* **client:** patch fetchMore to write to cache ([9cb7474](https://github.com/zino-app/graphql-flutter/commit/9cb7474e01ced66ddab6a78e397bc16843f50eca))
* **client:** use http 0.12.0+4 to fix a wrong content-type header on multipart request on http 0.12.0+3 ([ea8822c](https://github.com/zino-app/graphql-flutter/commit/ea8822ce03740a3e220fb3368c672013f27a8297)), closes [#525](https://github.com/zino-app/graphql-flutter/issues/525)
* **client:** use noCache for fetchMore, avoiding normalization ([da20541](https://github.com/zino-app/graphql-flutter/commit/da20541542657d8d41c1cb330d8e2a889ab82438))
* **docs:** remove moved onComplete ([31a0d2f](https://github.com/zino-app/graphql-flutter/commit/31a0d2f5a5d29575b26323f0ccb544e58e9a6077))
* switch test to AST from document string ([894dc53](https://github.com/zino-app/graphql-flutter/commit/894dc5340d3622aaf8e88df4481ebaa173362872))
* **docs:** use ast for examples ([d68616e](https://github.com/zino-app/graphql-flutter/commit/d68616ee8364b74d5e360dcd351b2564ebd549be))
* add eager result to stream, rebuild query widget on var change ([af89b19](https://github.com/zino-app/graphql-flutter/commit/af89b190798e027e692d9045f2409ee92640b762))
* bump gql dependency ([b55a891](https://github.com/zino-app/graphql-flutter/commit/b55a89131f128e0d4e3b7589b842937f75effe46))
* don't set default policies on options so defaults are applied ([fd95e37](https://github.com/zino-app/graphql-flutter/commit/fd95e37b3bb87e0c9d474e097d57ca58f74f706e))
* exception test cases ([001cb48](https://github.com/zino-app/graphql-flutter/commit/001cb488c36ccbff7d83c9fff9f0abbf0eb5f1f7))
* fix issues so example runs on latest stable ([87d8feb](https://github.com/zino-app/graphql-flutter/commit/87d8febbfd199f6f862d0dab84fc4dd04aa055c1))
* ignore `*.iml` and `.idea` ([361fdff](https://github.com/zino-app/graphql-flutter/commit/361fdffa9960ab5cde2958e1e6e8dc5f30689a4d))
* ignore linting errors from the core ([0612d44](https://github.com/zino-app/graphql-flutter/commit/0612d440f33ae33602095f331a9d9a847e42d7ae))
* ignore uri doesn't exist lint error ([e14349d](https://github.com/zino-app/graphql-flutter/commit/e14349db9e703059d07966561fd5e6d7b532b66d))
* individually suppress "deprecated_member_use_from_same_package" only ([3879f18](https://github.com/zino-app/graphql-flutter/commit/3879f18e7df5efc114349b8102507413e6db49d8))
* individually suppress "deprecated_member_use_from_same_package" only ([9216976](https://github.com/zino-app/graphql-flutter/commit/921697607c45389e7e1a8db73f0998886d22030c))
* pass queryId directly instead of ObservableQuery object ([405ae24](https://github.com/zino-app/graphql-flutter/commit/405ae24341cf9d80f92777bb82bfd3d73e4d2472))
* remove analysis_options.yaml as its ineffective ([0a8d05d](https://github.com/zino-app/graphql-flutter/commit/0a8d05d79c30fab87cd6fb6ae51ff91731a82ad0))
* remove equatable package ([0c32b14](https://github.com/zino-app/graphql-flutter/commit/0c32b142a4e94e9fe751e5679620fc78370e2faa))
* remove equitable package and update tests ([dbe4db5](https://github.com/zino-app/graphql-flutter/commit/dbe4db594fc13c6247764bc6b14926488997a723))
* subscriptions reconnect ([fd8f3d1](https://github.com/zino-app/graphql-flutter/commit/fd8f3d1b650dae9a5e961787e4adff36b391f98b))
* subscriptions reconnect ([c310db2](https://github.com/zino-app/graphql-flutter/commit/c310db280119a830915c864e68999321c5cd8f90))
* suppress fix: individually suppress "deprecated_member_use_from_same_package" only ([511630f](https://github.com/zino-app/graphql-flutter/commit/511630fddbde3482c07d969d7668b6befc016434))
* temporary disable assertion which is failing ([3cf7333](https://github.com/zino-app/graphql-flutter/commit/3cf73339520cc0665de7959ea0debbe6bf8ca64c))
* update .gitignore with standard flutter paths ([892fe36](https://github.com/zino-app/graphql-flutter/commit/892fe3609f2c81a4954dcc512463a8ac23709002))
* **graphql-flutter:** replace document string with AST Document ([23e40af](https://github.com/zino-app/graphql-flutter/commit/23e40af48f45dee196104e1cc745e22868432d7e))
* update starwars example ([8aaa99b](https://github.com/zino-app/graphql-flutter/commit/8aaa99b0b05da3723b7161aa285379a17d06b25e))
* **example:** depend on updated angel server, add paging example ([609c4ec](https://github.com/zino-app/graphql-flutter/commit/609c4eccde33733f72d6372dfb90a1834c3a38e4))
* **flutter:** prevent observable discarding in `MutationState.didChangeDependencies` ([baeca25](https://github.com/zino-app/graphql-flutter/commit/baeca25118bb11e67ef7cef9560ce279e09c4f4b))
* **flutter:** return callback results in case of futures to await ([c7d6fd1](https://github.com/zino-app/graphql-flutter/commit/c7d6fd1cf5a4d08f10f824c25510a4f6709e99d7))
* **graphql-flutter:** ignore ast errors in the core ([3b16f3f](https://github.com/zino-app/graphql-flutter/commit/3b16f3f8b47674c76d1fbf12b1153ab37358fba3))
* **packaging:** update rxdart and sdk min versions ([1980f22](https://github.com/zino-app/graphql-flutter/commit/1980f226183d0734a39f5f65efd6d1ef11accdbb)), closes [#497](https://github.com/zino-app/graphql-flutter/issues/497)
* **tests:** clobbered tests from library-level exceptions ([f76e165](https://github.com/zino-app/graphql-flutter/commit/f76e165d38572a25c9574b2f2370c43083cb3812))
* **tests:** fix failing tests seemingly to to ast-switch ([664fdd1](https://github.com/zino-app/graphql-flutter/commit/664fdd16b7ea0374de5bc5f09da65215026d3c1f))
* use AST for graphql client example ([edf7df6](https://github.com/zino-app/graphql-flutter/commit/edf7df60653008a3065c3a7baccc16814ab60254))
* use case else instead of detached or suspended ([9fb5aab](https://github.com/zino-app/graphql-flutter/commit/9fb5aab8ade7667e5c2143eb0869d344c23b37c9))


### Features

* **client:** add error link ([de9714a](https://github.com/zino-app/graphql-flutter/commit/de9714a5859b873620ba283166e6dd0b741076df)), closes [#419](https://github.com/zino-app/graphql-flutter/issues/419) [#440](https://github.com/zino-app/graphql-flutter/issues/440)
* **client:** cache.reset() added ([8c4f2e2](https://github.com/zino-app/graphql-flutter/commit/8c4f2e20ff7fd479cd4a634859716b501166e96d))
* **client:** introduce Policies class for options and add defaults to client ([fa24aab](https://github.com/zino-app/graphql-flutter/commit/fa24aaba639f1e6899139643ada06f2fd8f4a958))
* **client:** library-level exception handling ([20e57bd](https://github.com/zino-app/graphql-flutter/commit/20e57bdfec7ccc857c7e9bdcc531736db564aaf0))
* **client:** library-level exceptions ([8976cfc](https://github.com/zino-app/graphql-flutter/commit/8976cfc85b3e9f0a2a432f19ce88ee6526115468))
* **client:** support defining operations from document AST ([fa2db11](https://github.com/zino-app/graphql-flutter/commit/fa2db1177380e543ce20384638e20a1770860f03))
* **client:** support joining multiple links at once ([9565244](https://github.com/zino-app/graphql-flutter/commit/95652440f6d688991700673022e690d8cd04eb54))
* attempt to call mutation callbacks from mutation method ([e323a4d](https://github.com/zino-app/graphql-flutter/commit/e323a4d58abea8a8d9f472b4b004b61708cb1e8c))
* better message on UnhandledFailure ([eccab11](https://github.com/zino-app/graphql-flutter/commit/eccab1113b85ef5354191d8600dc3da8e3f7a591))
* document exception handling ([b38e2a3](https://github.com/zino-app/graphql-flutter/commit/b38e2a3d900c36c1082e242da5e904d0d3f2dc81))
* **flutter:** add mutation callback for onError ([1ff0b8f](https://github.com/zino-app/graphql-flutter/commit/1ff0b8f35c4ac1df5dfd689bfa413f5406b7b26d))
* **graphql-client:** re-export parseString as gql ([dcd5508](https://github.com/zino-app/graphql-flutter/commit/dcd5508e824eff1d944c767d5c72c107f8102a62))
* update examples to gql instead of parse string ([7b9ac57](https://github.com/zino-app/graphql-flutter/commit/7b9ac57d356c282a85313b0436fb58db1f772fcf))
* updating example ([1a1bc43](https://github.com/zino-app/graphql-flutter/commit/1a1bc4337c80bc8c0dbb20cae66f489a3bf5425b))
* use equatable package to make it easier to compare links ([a7ed072](https://github.com/zino-app/graphql-flutter/commit/a7ed072b37f734d089b979c740435fe28effe30c))


### BREAKING CHANGES

* **packaging:** projects dependent on old sdk/rxdart versions wouldn't build,
there is a way to override rxdart dependency with dependency_override
(we don't use Observable features in these places, so it should be compatible with older version)
there is no way to override min sdk version outside of a project
* **client:** replaces result.errors with result.exception

# [3.0.0-beta.3](https://github.com/zino-app/graphql-flutter/compare/v3.0.0-beta.2...v3.0.0-beta.3) (2020-01-09)


### Bug Fixes

* **client:** use http 0.12.0+4 to fix a wrong content-type header on multipart request on http 0.12.0+3 ([ea8822c](https://github.com/zino-app/graphql-flutter/commit/ea8822ce03740a3e220fb3368c672013f27a8297)), closes [#525](https://github.com/zino-app/graphql-flutter/issues/525)

# [3.0.0-beta.2](https://github.com/zino-app/graphql-flutter/compare/v3.0.0-beta.1...v3.0.0-beta.2) (2020-01-08)


### Bug Fixes

* **packaging:** update rxdart and sdk min versions ([1980f22](https://github.com/zino-app/graphql-flutter/commit/1980f226183d0734a39f5f65efd6d1ef11accdbb)), closes [#497](https://github.com/zino-app/graphql-flutter/issues/497)


### BREAKING CHANGES

* **packaging:** projects dependent on old sdk/rxdart versions wouldn't build,
there is a way to override rxdart dependency with dependency_override
(we don't use Observable features in these places, so it should be compatible with older version)
there is no way to override min sdk version outside of a project

# [3.0.0-beta.1](https://github.com/zino-app/graphql-flutter/compare/v2.1.0...v3.0.0-beta.1) (2019-12-22)


### Bug Fixes

* **cache:** add value == and hashCode to lazy cache map, fix traversal ([617dde7](https://github.com/zino-app/graphql-flutter/commit/617dde77e30505c9c85ba13570f40328e3b47d87))
* **cache:** AppLifecycleState.{suspending -> detached} ([8bc7b14](https://github.com/zino-app/graphql-flutter/commit/8bc7b14b182831c2df4824c661e3c87eaa66f78a))
* **ci:** attempt to fix ci ([4fac2e4](https://github.com/zino-app/graphql-flutter/commit/4fac2e422f0a868b1abfffdf94d3fe614ac7ca4f))
* **client:** default toEncodable ([5f938e4](https://github.com/zino-app/graphql-flutter/commit/5f938e4fa7691aa50bb07978bc547c0483833d90))
* **client:** export operation and fetch results ([5dcbae5](https://github.com/zino-app/graphql-flutter/commit/5dcbae5c410cb2f5d5775138ea9c77b66628d5aa))
* **client:** make fetchMore valid with default original document again ([faa3779](https://github.com/zino-app/graphql-flutter/commit/faa37791a309bd47405bf2d8a2902595eb62684e))
* **client:** organize exports alphabetically ([a322339](https://github.com/zino-app/graphql-flutter/commit/a3223394825ed07806359b9fd4b9b094597197bb))
* **client:** patch fetchMore to write to cache ([9cb7474](https://github.com/zino-app/graphql-flutter/commit/9cb7474e01ced66ddab6a78e397bc16843f50eca))
* **client:** use noCache for fetchMore, avoiding normalization ([da20541](https://github.com/zino-app/graphql-flutter/commit/da20541542657d8d41c1cb330d8e2a889ab82438))
* **docs:** remove moved onComplete ([31a0d2f](https://github.com/zino-app/graphql-flutter/commit/31a0d2f5a5d29575b26323f0ccb544e58e9a6077))
* **docs:** use ast for examples ([d68616e](https://github.com/zino-app/graphql-flutter/commit/d68616ee8364b74d5e360dcd351b2564ebd549be))
* **example:** depend on updated angel server, add paging example ([609c4ec](https://github.com/zino-app/graphql-flutter/commit/609c4eccde33733f72d6372dfb90a1834c3a38e4))
* **flutter:** prevent observable discarding in `MutationState.didChangeDependencies` ([baeca25](https://github.com/zino-app/graphql-flutter/commit/baeca25118bb11e67ef7cef9560ce279e09c4f4b))
* **flutter:** return callback results in case of futures to await ([c7d6fd1](https://github.com/zino-app/graphql-flutter/commit/c7d6fd1cf5a4d08f10f824c25510a4f6709e99d7))
* pass queryId directly instead of ObservableQuery object ([405ae24](https://github.com/zino-app/graphql-flutter/commit/405ae24341cf9d80f92777bb82bfd3d73e4d2472))
* **graphql-flutter:** ignore ast errors in the core ([3b16f3f](https://github.com/zino-app/graphql-flutter/commit/3b16f3f8b47674c76d1fbf12b1153ab37358fba3))
* add eager result to stream, rebuild query widget on var change ([af89b19](https://github.com/zino-app/graphql-flutter/commit/af89b190798e027e692d9045f2409ee92640b762))
* bump gql dependency ([b55a891](https://github.com/zino-app/graphql-flutter/commit/b55a89131f128e0d4e3b7589b842937f75effe46))
* don't set default policies on options so defaults are applied ([fd95e37](https://github.com/zino-app/graphql-flutter/commit/fd95e37b3bb87e0c9d474e097d57ca58f74f706e))
* exception test cases ([001cb48](https://github.com/zino-app/graphql-flutter/commit/001cb488c36ccbff7d83c9fff9f0abbf0eb5f1f7))
* fix issues so example runs on latest stable ([87d8feb](https://github.com/zino-app/graphql-flutter/commit/87d8febbfd199f6f862d0dab84fc4dd04aa055c1))
* ignore `*.iml` and `.idea` ([361fdff](https://github.com/zino-app/graphql-flutter/commit/361fdffa9960ab5cde2958e1e6e8dc5f30689a4d))
* ignore linting errors from the core ([0612d44](https://github.com/zino-app/graphql-flutter/commit/0612d440f33ae33602095f331a9d9a847e42d7ae))
* ignore uri doesn't exist lint error ([e14349d](https://github.com/zino-app/graphql-flutter/commit/e14349db9e703059d07966561fd5e6d7b532b66d))
* individually suppress "deprecated_member_use_from_same_package" only ([3879f18](https://github.com/zino-app/graphql-flutter/commit/3879f18e7df5efc114349b8102507413e6db49d8))
* individually suppress "deprecated_member_use_from_same_package" only ([9216976](https://github.com/zino-app/graphql-flutter/commit/921697607c45389e7e1a8db73f0998886d22030c))
* remove analysis_options.yaml as its ineffective ([0a8d05d](https://github.com/zino-app/graphql-flutter/commit/0a8d05d79c30fab87cd6fb6ae51ff91731a82ad0))
* remove equatable package ([0c32b14](https://github.com/zino-app/graphql-flutter/commit/0c32b142a4e94e9fe751e5679620fc78370e2faa))
* remove equitable package and update tests ([dbe4db5](https://github.com/zino-app/graphql-flutter/commit/dbe4db594fc13c6247764bc6b14926488997a723))
* subscriptions reconnect ([c310db2](https://github.com/zino-app/graphql-flutter/commit/c310db280119a830915c864e68999321c5cd8f90))
* subscriptions reconnect ([fd8f3d1](https://github.com/zino-app/graphql-flutter/commit/fd8f3d1b650dae9a5e961787e4adff36b391f98b))
* suppress fix: individually suppress "deprecated_member_use_from_same_package" only ([511630f](https://github.com/zino-app/graphql-flutter/commit/511630fddbde3482c07d969d7668b6befc016434))
* switch test to AST from document string ([894dc53](https://github.com/zino-app/graphql-flutter/commit/894dc5340d3622aaf8e88df4481ebaa173362872))
* temporary disable assertion which is failing ([3cf7333](https://github.com/zino-app/graphql-flutter/commit/3cf73339520cc0665de7959ea0debbe6bf8ca64c))
* update .gitignore with standard flutter paths ([892fe36](https://github.com/zino-app/graphql-flutter/commit/892fe3609f2c81a4954dcc512463a8ac23709002))
* update starwars example ([8aaa99b](https://github.com/zino-app/graphql-flutter/commit/8aaa99b0b05da3723b7161aa285379a17d06b25e))
* use AST for graphql client example ([edf7df6](https://github.com/zino-app/graphql-flutter/commit/edf7df60653008a3065c3a7baccc16814ab60254))
* **graphql-flutter:** replace document string with AST Document ([23e40af](https://github.com/zino-app/graphql-flutter/commit/23e40af48f45dee196104e1cc745e22868432d7e))
* **tests:** clobbered tests from library-level exceptions ([f76e165](https://github.com/zino-app/graphql-flutter/commit/f76e165d38572a25c9574b2f2370c43083cb3812))
* **tests:** fix failing tests seemingly to to ast-switch ([664fdd1](https://github.com/zino-app/graphql-flutter/commit/664fdd16b7ea0374de5bc5f09da65215026d3c1f))
* use case else instead of detached or suspended ([9fb5aab](https://github.com/zino-app/graphql-flutter/commit/9fb5aab8ade7667e5c2143eb0869d344c23b37c9))


### Features

* **client:** add error link ([de9714a](https://github.com/zino-app/graphql-flutter/commit/de9714a5859b873620ba283166e6dd0b741076df)), closes [#419](https://github.com/zino-app/graphql-flutter/issues/419) [#440](https://github.com/zino-app/graphql-flutter/issues/440)
* **client:** cache.reset() added ([8c4f2e2](https://github.com/zino-app/graphql-flutter/commit/8c4f2e20ff7fd479cd4a634859716b501166e96d))
* **client:** introduce Policies class for options and add defaults to client ([fa24aab](https://github.com/zino-app/graphql-flutter/commit/fa24aaba639f1e6899139643ada06f2fd8f4a958))
* **client:** library-level exception handling ([20e57bd](https://github.com/zino-app/graphql-flutter/commit/20e57bdfec7ccc857c7e9bdcc531736db564aaf0))
* **client:** library-level exceptions ([8976cfc](https://github.com/zino-app/graphql-flutter/commit/8976cfc85b3e9f0a2a432f19ce88ee6526115468))
* **client:** support defining operations from document AST ([fa2db11](https://github.com/zino-app/graphql-flutter/commit/fa2db1177380e543ce20384638e20a1770860f03))
* **client:** support joining multiple links at once ([9565244](https://github.com/zino-app/graphql-flutter/commit/95652440f6d688991700673022e690d8cd04eb54))
* attempt to call mutation callbacks from mutation method ([e323a4d](https://github.com/zino-app/graphql-flutter/commit/e323a4d58abea8a8d9f472b4b004b61708cb1e8c))
* better message on UnhandledFailure ([eccab11](https://github.com/zino-app/graphql-flutter/commit/eccab1113b85ef5354191d8600dc3da8e3f7a591))
* document exception handling ([b38e2a3](https://github.com/zino-app/graphql-flutter/commit/b38e2a3d900c36c1082e242da5e904d0d3f2dc81))
* **flutter:** add mutation callback for onError ([1ff0b8f](https://github.com/zino-app/graphql-flutter/commit/1ff0b8f35c4ac1df5dfd689bfa413f5406b7b26d))
* **graphql-client:** re-export parseString as gql ([dcd5508](https://github.com/zino-app/graphql-flutter/commit/dcd5508e824eff1d944c767d5c72c107f8102a62))
* update examples to gql instead of parse string ([7b9ac57](https://github.com/zino-app/graphql-flutter/commit/7b9ac57d356c282a85313b0436fb58db1f772fcf))
* updating example ([1a1bc43](https://github.com/zino-app/graphql-flutter/commit/1a1bc4337c80bc8c0dbb20cae66f489a3bf5425b))
* use equatable package to make it easier to compare links ([a7ed072](https://github.com/zino-app/graphql-flutter/commit/a7ed072b37f734d089b979c740435fe28effe30c))


### BREAKING CHANGES

* **client:** replaces result.errors with result.exception

See [GitHub Releases](https://github.com/zino-app/graphql-flutter/releases).

* Loosened `initPayload` to `dynamic` to support many use-cases,
  Removed `InitOperation`'s excessive and inconsistent json encoding.
  Old implmentation can still be utilized as `legacyInitPayload`
  until deprecation

* Fixed broken anonymous operations
