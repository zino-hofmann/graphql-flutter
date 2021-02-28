# Architecture

`graphql/client.dart` is heavily modeled on the [Apollo Client]. 
Many of its newer or "fancier" features we do not have the bandwidth to
support, but it is still commonly our reference point for design for
`graphql` and other libraries in the ecosystem. Apollo is the source of
our cache design and API, the execution "link" layer, and the type
policies in the [`normalize`] package.

## Structure & Development
```bash
tree -L 3 -d .
.
├── example
│   ├── bin
│   └── lib
├── lib
│   └── src
│       ├── cache      # cache and store abstractions
│       ├── core       # 
│       ├── exceptions # client exceptions / link exception wrappers
│       ├── links      # custom and re-exported gql_links
│       ├── scheduler  # used by ObservableQuery for polling
│       └── utilities  # helpers like gql
└── test
    └── cache
```
Of the subpackages in `lib/src`, most development work is done in the
`cache`, `core`, and `lib/src/links/websocket_link`.
It is also sometimes necessary to contribute to [`gql_link`] dependencies
for execution layer issues and [`normalize`] for cache normalization
issues, and valuable to understand both.

## Core
```bash
tree lib/src/core
├── _base_options.dart # shared base class for *Options classes
├── _data_class.dart   # stopgap helper for a truly immutable options API
├── _query_write_handling.dart # some common write handling extracted from
│                              # the QueryManager.
├── core.dart             # reexports.
├── fetch_more.dart       # shared fetchMore logic.
├── mutation_options.dart # MutationOptions and MutationCallbackHandler.
├── observable_query.dart # the guts of watchQuery/watchMutation.
├── policies.dart         # Policies and default policies.
├── query_manager.dart    # The central execution entrypoints for
│                         # query, mutate, and subscribe.
├── query_options.dart    # QueryOptions, WatchQueryOptions, FetchMoreOptions
└── query_result.dart     # QueryResult and MultiSourceResult
```
The `core` module contains the vast majority of the main execution path,
with the `QueryManager` handling the logic for individual requests,
including determining when to do things like read optimistic data, write
to the cache, etc (though the guts of the latter is mostly in
`_query_write_handling.dart` now).

One confusing aspect of `cor` is that `*Options` and `QueryResult` are not
well integrated with `Request` and `Response` from the newer
[`gql_link`] system.

Finally, the `ObservableQuery` is the overpowered workhorse that enables
the streaming design of `graphql_flutter`. It is also used in `Mutation`,
which is why it has an `onData` callback system. The conflation of `Query`
and `Mutation` here is not good, and actually lead to a long-standing
bug where mutation results were overwritten that was only resolved in [#795].

## Cache
```bash
tree lib/src/cache
├── _normalizing_data_proxy.dart  # Operation normalization code shared by 
│                                 # GraphQLCache and OptimisticProxy.
├── _optimistic_transactions.dart # OptimisticProxy for optimistic transactions.
├── cache.dart      # Puts it all together and implements "optimistic layers."
├── data_proxy.dart # The abstract GraphQLDataProxy api.
├── fragment.dart   # `gql_exec`-like API for readFragment and writeFragment.
├── hive_store.dart # The recommended store using hive.
└── store.dart      # The Store abstraction.
```

The `GraphQLCache` implements a layered optimism system similar to apollo,
allowing for clean separation of the optimistic data from each mutation
that is then merged at read time.

Other than the ability for users to provide their own custom `Store`, the
rest of the cache normalization magic is handled by the [`normalize`]
library.

## The Rest

`exceptions` defines a few custom `LinkExceptions` as well as the
`OperationException` wrapper. The `QueryManager` wraps all requests in
try/catch and should never throw itself, always wrapping errors in
an `OperationException` for users to deal with as they see fit.

`scheduler` is injected into `ObservableQuery` and is kinda
awkwardly placed. I've only ever had to touch it once or twice.

We re-export a lot of links from `gql`, and a lot of the code in
`gql_http_link` came from `graphql/client.dart` initially.

## Future plans

* [#712]: Update and switch to [`gql_dio_link`] link (this is
  going to be hard).
* [#798]: Decoupling the mutation logic from `ObservableQuery`.
* [#652]: Break client features into links and link compositions.

[Apollo Client]: https://www.apollographql.com/docs/react/
[`gql_link`]: https://github.com/gql-dart/gql/tree/master/links/gql_link
[`gql_http_link`]: https://github.com/gql-dart/gql/tree/master/links/gql_http_link
[`gql_dio_link`]: https://github.com/gql-dart/gql/tree/master/links/gql_dio_link
[`normalize`]: https://github.com/gql-dart/ferry/tree/master/normalize
[#795]: https://github.com/zino-app/graphql-flutter/issues/795
[#712]: https://github.com/zino-app/graphql-flutter/issues/712
[#798]: https://github.com/zino-app/graphql-flutter/issues/798
[#652]: https://github.com/zino-app/graphql-flutter/issues/652
