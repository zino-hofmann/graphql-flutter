# [4.0.0-beta.1](https://github.com/zino-app/graphql-flutter/4.0.0-beta.1) (2020-10-06)

`v4` reworks a lot of the internals of the core `graphql/client.dart` (and thus `graphql_flutter`).

Please see the [v4 changelog](../../changelog-v3-v4.md) for more details, and the updated READMEs for more extensive documentation.


# 4.0.0-alpha.11 (2020-09-26)

* **hotfix(client)**: `gql_http_link==0.3.2` for custom toJsons closing #734 ([98b8cf7](https://github.com/zino-app/graphql-flutter/commit/98b8cf771e9f982741d5041bd4a4f017ac46dc91))


# 4.0.0-alpha.10 (2020-09-26)

* **hotfix(client)**: `gql_http_link==0.3.1` fix for bool json encoding support ([38b2fd2](https://github.com/zino-app/graphql-flutter/commit/38b2fd2abbb7e3439e35d139538816beb9e10c40 ))


# 4.0.0-alpha.9 (2020-09-25)

:warning:  breaking: the `cache.readFragment / cache.readFragment` API has been reworked:
```diff
  final fragDoc = gql(...);

  final idFields = { '__typename': 'MyType', 'id': 1 }

  final fragmentData = {
    'myField': 'updatedValue',
    'someNewField': [
      {'newData': false}
    ],
  };

+ // or Fragment(document: fragDoc).asRequest(idFields: idFields)
+ final fragmentRequest = FragmentRequest(
+   fragment: Fragment(
+     document: fragDoc,
+   ),
+   idFields: idFields,
+ );

  cache.writeFragment(
-   fragment: fragDoc,
-   idFields: idFields,
+   fragmentRequest,
    data: fragmentData,
  );
```
This was done because I (@micimize) wanted to make it more consistent with `cache.readQuery`/`cache.writeQuery` before `beta`.

* **client**: refactor(client): Fragment and FragmentRequest for more normalized api ([2f04058](https://github.com/zino-app/graphql-flutter/commit/2f04058b0dd2d739cd423ccea616c4574f9cf9eb))
* **docs**:  update docs, add more sections ([00f4a97](https://github.com/zino-app/graphql-flutter/commit/00f4a971fa4b1aa14b568b16b25b31b98ef70a4b))


# 4.0.0-alpha.8 (2020-09-24)

This was mostly a prep release for the first v4 beta.

* **client**: cache proxy methods on cache, resetStore with optional refetchQueries ([ba7134a](https://github.com/zino-app/graphql-flutter/commit/ba7134aad4f755c420ebf0f600898c090df52da7))
* **test(client)**: more cache and store tests ([a9eed21](https://github.com/zino-app/graphql-flutter/commit/a9eed2133c273c1d938677e4694e26f643ca9d06))
* **examples**: merge and update flutter_bloc changes ([ac4759a](https://github.com/zino-app/graphql-flutter/commit/ac4759a474b65b3ed2f5cc0b3779ec35e53492c3))
* **docs**: correct multipart example ([f9d1adb](https://github.com/zino-app/graphql-flutter/commit/f9d1adb6545685cd4534955e27eb498ca9f9a6cb))
* **chore**: re-merge changelog and templates ([9db0b44](https://github.com/zino-app/graphql-flutter/commit/9db0b44d546a7c7193d68dba4541b7acaa255dac))
* **tests**: restore old websocket client tests ([3e4870c](https://github.com/zino-app/graphql-flutter/commit/3e4870ce4b67bd9a8716af54b26061eac801c44d))
* **refactor**: pollInterval is now a Duration ([fe02bb8](https://github.com/zino-app/graphql-flutter/commit/fe02bb8daed67ae635b97a8d4fe34fa015bbcdd8))
* **chore**: I think fixes coverage and lint ([d37e81c](https://github.com/zino-app/graphql-flutter/commit/d37e81c855e0013b965613a41f1531e8b33b4292))


# 4.0.0-alpha.7 (2020-09-17)

`GraphQLClient` now `implements GraphQLDataProxy`, exposing `readQuery`, `writeQuery`, `readFragment`, and `writeFragment`. The writing methods also trigger rebroadcasts, closing #728.

It also adds an experimental `client.resetStore({refetchQueries = true})` for refetching the results of all observed queries (not mutations), and expose `cache.store` with a **WARNING** about direct access.

* **client**: cache proxy methods on cache, resetStore with optional refetchQueries ([ba7134a](https://github.com/zino-app/graphql-flutter/commit/ba7134aad4f755c420ebf0f600898c090df52da7))
* **client**: refetchSafeQueries, clarify rebroadcast calls in docs ([e45b240](https://github.com/zino-app/graphql-flutter/commit/e45b240ae5992edb63e02ddd01ddc5dc9d955795))
* **client**: expose store, cleanup ([6fc5e7e](https://github.com/zino-app/graphql-flutter/commit/6fc5e7e0878231ca2e3da465a16a8ef38906031e))
* **client**: add isMutation etc helpers to Options types ([04e7888](https://github.com/zino-app/graphql-flutter/commit/04e7888e5c1d4f8a61e786a7e541bfaf0116accd))
* **fix**: only queries are refetch safe ([1e93376](https://github.com/zino-app/graphql-flutter/commit/1e9337633d3c0b6ea61bc3d83fd7d9b1f2f20a7a))
* **refactor**: clean up unused helpers, clarify shoudRebroadcast ([1cf6478](https://github.com/zino-app/graphql-flutter/commit/1cf6478262f9d1ad24d12ae4ddc9af5a85cf94e9))


# 4.0.0-alpha.6 (2020-09-12)
* **client**: fix subscription initial result from cache ([de66cff](https://github.com/zino-app/graphql-flutter/commit/de66cffab0c13f1d705bb4538f55a2e11b653a4f))


# 4.0.0-alpha.5 (2020-09-12)
* **cache**: sanitize multipart files for cache. ([4ceb800](https://github.com/zino-app/graphql-flutter/commit/4ceb8006baf4539ab423e3b3a229f194cc2eac45))


# 4.0.0-alpha.4 (2020-09-05)
* **client**: bring back old websocket link with gql adapter layer ([496d994](https://github.com/zino-app/graphql-flutter/commit/496d994e06148fbad1a394c7b3d68e43a8e8acaf))
* **client**: multipart file support from `gql_http_link==0.3.0` ([c2733ca](https://github.com/zino-app/graphql-flutter/commit/c2733ca3d33b1b50afc5b2ef7809fd1f4aa41500))


# 4.0.0-alpha.3 (2020-07-27)
* **client**: don't close mutations after callbacks ([2ba6c74](https://github.com/zino-app/graphql-flutter/commit/2ba6c743a7317c3df05c3f1c5e8e3e3cd44d6827))
* **examples**: update ios files for graphql_flutter/example ([5b6e3d0](https://github.com/zino-app/graphql-flutter/commit/5b6e3d06a7dc56888dcbfc4c395ea51985c10f1c))


# 4.0.0-alpha.2 (2020-07-24)
* **client**: simplified AuthLink ([0b3fbd9](https://github.com/zino-app/graphql-flutter/commit/0b3fbd9a4d3d0f9bded2bd9a9fdf26e3bfe983df))
* **docs**: direct cache access in changelog ([1f21927](https://github.com/zino-app/graphql-flutter/commit/1f2192710531a920be6c7df1b22da105c8cdc11c))
* **examples**: starwars hivestore usage ([2f874ec](https://github.com/zino-app/graphql-flutter/commit/2f874ecde038e16332bb51243afb167ac0421e35))
* **client**: `HiveStore` api improvements ([2d1a7f2](https://github.com/zino-app/graphql-flutter/commit/2d1a7f2e367f57f6ff2f968814045fb5edf15085))
* **fix**: `FetchMoreOptions` was throwing without `document` ([2d1a7f2](https://github.com/zino-app/graphql-flutter/commit/2d1a7f2e367f57f6ff2f968814045fb5edf15085))
* **fix**: `deeplyMergeLeft` type error ([65fdcb2](https://github.com/zino-app/graphql-flutter/commit/65fdcb2600257f8982496e5191424f42365f7f39))


# 4.0.0-alpha.1 (2020-06-17)
* **client:** `maybeRebroadcast` on `mutation` ([75393c2](https://github.com/zino-app/graphql-flutter/commit/75393c2763c8b232aea7a719fa54d53a5885f995))


# 4.0.0-alpha.0 (2020-06-07)

See the [v4 changelog](../../changelog-v3-v4.md)

# [3.1.0](https://github.com/zino-app/graphql-flutter/compare/v3.0.2...v3.1.0) (2020-07-27)


### Bug Fixes

* **ci:** add changelog back ([3e63c3e](https://github.com/zino-app/graphql-flutter/commit/3e63c3eddf142c99918d58fcd9a8828106327eec))
* **ci:** Sync master into beta ([2a0507e](https://github.com/zino-app/graphql-flutter/commit/2a0507ec3ea492ff0cc748fab80ee2258efe0b56))
* **client:** Throw a ClientException on non-json responses, to be ([7d538e1](https://github.com/zino-app/graphql-flutter/commit/7d538e16dd626d2ff7c4f963031ff6c825f24269)), closes [#552](https://github.com/zino-app/graphql-flutter/issues/552)
* **client:** translateNetworkFailure when no route to host ([877bdb8](https://github.com/zino-app/graphql-flutter/commit/877bdb8b2e9093f58f26f5d1abf2460aa5e3e910))
* **examples:** rebuilt & tested starwars example ([2aaffeb](https://github.com/zino-app/graphql-flutter/commit/2aaffeb835dceeb594e3cccb92cb552933609c70))
* **examples/starwars:** use git dependency for graphql_starwars_test_server ([0facc48](https://github.com/zino-app/graphql-flutter/commit/0facc4880b3cfcb6abe9f4e7ed5609b97f3fab42))
* **flutter:** Query.didUpdateWidget and policy overrides ([6672e44](https://github.com/zino-app/graphql-flutter/commit/6672e44f1ab9fcb03a3bc046d4822c9c8aca5ef6))
* **flutter:** widgets make unnecessary requests when dependencies change ([c487931](https://github.com/zino-app/graphql-flutter/commit/c487931db3a5f0b62b6c8e2387b1c630a523b627))
* **packaging:** correct dependencies, remove authors ([13f6a43](https://github.com/zino-app/graphql-flutter/commit/13f6a4356c05c6ad78e90f9b0f73579f86cf36db))
* **packaging:** don't commit .flutter-plugins-dependencies ([f77dafa](https://github.com/zino-app/graphql-flutter/commit/f77dafadb2314761341b35ac250460424089e718))
* **packaging:** upgrade rxdart ([20364a9](https://github.com/zino-app/graphql-flutter/commit/20364a9bbea6f2fb8f90001e7301990486b5263d))
* **release:** RunMutation return type definition ([9cb9658](https://github.com/zino-app/graphql-flutter/commit/9cb9658f745139080e435856682ea0148d814098))
* **tests:** don't factor tests into coverage scores ([4a9bcd4](https://github.com/zino-app/graphql-flutter/commit/4a9bcd4c708e955dbfcd432f0ce803541a343487))


### Features

* **examples/starwars:** add web support ([3b5bc93](https://github.com/zino-app/graphql-flutter/commit/3b5bc932042f3980180dea737cb84a45db1e846d))
* **graphql:** custom auth headerKey ([fc01ea5](https://github.com/zino-app/graphql-flutter/commit/fc01ea548a6e3adc47c1c927efd933b67cc396af))

# [3.1.0-beta.7](https://github.com/zino-app/graphql-flutter/compare/v3.1.0-beta.6...v3.1.0-beta.7) (2020-06-04)


### Bug Fixes

* **ci:** add changelog back ([3e63c3e](https://github.com/zino-app/graphql-flutter/commit/3e63c3eddf142c99918d58fcd9a8828106327eec))
* **ci:** Sync master into beta ([2a0507e](https://github.com/zino-app/graphql-flutter/commit/2a0507ec3ea492ff0cc748fab80ee2258efe0b56))
* **client:** FetchMoreOptions bug with operator precedence ([f8e05af](https://github.com/zino-app/graphql-flutter/commit/f8e05af52f9720eed612f13b513d25f2456a8726))

## [3.0.2](https://github.com/zino-app/graphql-flutter/compare/v3.0.1...v3.0.2) (2020-05-18)


### Bug Fixes

* **client:** FetchMoreOptions bug with operator precedence ([f8e05af](https://github.com/zino-app/graphql-flutter/commit/f8e05af52f9720eed612f13b513d25f2456a8726))

# [3.1.0-beta.6](https://github.com/zino-app/graphql-flutter/compare/v3.1.0-beta.5...v3.1.0-beta.6) (2020-05-16)


### Bug Fixes

* **packaging:** correct dependencies, remove authors ([a22d504](https://github.com/zino-app/graphql-flutter/commit/a22d5041a556cca8fa52ab59119ff8fd7ad652ec))

# [3.1.0-beta.5](https://github.com/zino-app/graphql-flutter/compare/v3.1.0-beta.4...v3.1.0-beta.5) (2020-05-10)


### Bug Fixes

* **packaging:** upgrade rxdart ([20364a9](https://github.com/zino-app/graphql-flutter/commit/20364a9bbea6f2fb8f90001e7301990486b5263d))


### Features

* **graphql:** custom auth headerKey ([167fac5](https://github.com/zino-app/graphql-flutter/commit/167fac5366160aa8384c3d87c900b38b065f6d59))

# [3.1.0-beta.4](https://github.com/zino-app/graphql-flutter/compare/v3.1.0-beta.3...v3.1.0-beta.4) (2020-04-21)


### Bug Fixes

* **examples:** rebuilt & tested starwars example ([f8e19f1](https://github.com/zino-app/graphql-flutter/commit/f8e19f1e1f6d41a68c8bd54cd4b2613be7c81f10))
* **packaging:** don't commit .flutter-plugins-dependencies ([0857030](https://github.com/zino-app/graphql-flutter/commit/0857030d390e131d132c3d0d5984693a4462ae22))

# [3.1.0-beta.3](https://github.com/zino-app/graphql-flutter/compare/v3.1.0-beta.2...v3.1.0-beta.3) (2020-04-20)


### Bug Fixes

* **flutter:** Query.didUpdateWidget and policy overrides ([32f6172](https://github.com/zino-app/graphql-flutter/commit/32f617240b9a2a7ddb00e8d654384c89e6770c76))
* **style:** use curly braces ([42f4da4](https://github.com/zino-app/graphql-flutter/commit/42f4da4cb5ddb9f76c34a5946eb1bf662d138cbf))
* **tests:** don't factor tests into coverage scores ([4a9bcd4](https://github.com/zino-app/graphql-flutter/commit/4a9bcd4c708e955dbfcd432f0ce803541a343487))

## [3.0.1](https://github.com/zino-app/graphql-flutter/compare/v3.0.0...v3.0.1) (2020-04-20)


### Bug Fixes

* **style:** use curly braces ([42f4da4](https://github.com/zino-app/graphql-flutter/commit/42f4da4cb5ddb9f76c34a5946eb1bf662d138cbf))

# [3.1.0-beta.2](https://github.com/zino-app/graphql-flutter/compare/v3.1.0-beta.1...v3.1.0-beta.2) (2020-04-12)


### Bug Fixes

* **flutter:** widgets make unnecessary requests when dependencies change ([31936ff](https://github.com/zino-app/graphql-flutter/commit/31936ff2c3cf8cc2dcf6b017868fec71320f080a))

# [3.1.0-beta.1](https://github.com/zino-app/graphql-flutter/compare/v3.0.1-beta.3...v3.1.0-beta.1) (2020-03-30)


### Bug Fixes

* **examples/starwars:** use git dependency for graphql_starwars_test_server ([0facc48](https://github.com/zino-app/graphql-flutter/commit/0facc4880b3cfcb6abe9f4e7ed5609b97f3fab42))


### Features

* **examples/starwars:** add web support ([f52b1db](https://github.com/zino-app/graphql-flutter/commit/f52b1dbc5bbafd0933e2b5b51b8f09c18462bd0b))

## [3.0.1-beta.3](https://github.com/zino-app/graphql-flutter/compare/v3.0.1-beta.2...v3.0.1-beta.3) (2020-03-10)


### Bug Fixes

* **release:** RunMutation return type definition ([9cb9658](https://github.com/zino-app/graphql-flutter/commit/9cb9658f745139080e435856682ea0148d814098))

## [3.0.1-beta.2](https://github.com/zino-app/graphql-flutter/compare/v3.0.1-beta.1...v3.0.1-beta.2) (2020-02-14)


### Bug Fixes

* **client:** Throw a ClientException on non-json responses, to be ([7d538e1](https://github.com/zino-app/graphql-flutter/commit/7d538e16dd626d2ff7c4f963031ff6c825f24269)), closes [#552](https://github.com/zino-app/graphql-flutter/issues/552)

## [3.0.1-beta.1](https://github.com/zino-app/graphql-flutter/compare/v3.0.0...v3.0.1-beta.1) (2020-01-21)


### Bug Fixes

* **client:** translateNetworkFailure when no route to host ([e8b6322](https://github.com/zino-app/graphql-flutter/commit/e8b6322cc537df8cbc829be0f6182bdfdf6d0779))

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
