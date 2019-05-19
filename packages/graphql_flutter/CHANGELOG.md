See [GitHub Releases](https://github.com/zino-app/graphql-flutter/releases).

### [1.0.1-beta] - April 27 2019

We now have a (beta) stand-alone client!

For those who want to try it out, checkout the [`graphql/client.dart` 1.0.1-beta](https://pub.dartlang.org/packages/graphql/versions/1.0.1-beta).

### [1.0.0+4] - April 23 2019

Fix dart 2.3 compilation issue @mateusfsilva

## [1.0.0+3] - April 23 2019

_Actually_ Fixes for some minor linting issues, as well as a stack overflow edgecase with complex cache structures

#### [1.0.0+2] - April 22 2019

## [1.0.0+1] - April 21 2019

Most changes here are from @micimize in #199

#### Breaking changes

- Broke `onCompleted` signature because it didn't match apollo's and is only called when `data` is ready.
- Moved `_inMemoryCache` to `@protected data` for testing/override purposes (important for `OptimisticPatches`
- Updated the example to use optimism
- adds a `refetch` argument to the `Query` `builder`

#### Fixes / Enhancements

- subscription and null variable fixes from @yunyu
- many documentation fixes and additions From @mainawycliffe
- disable polling with 0 interval @mainawycliffe
- Added `OptimisticCache` and related attributes to `QueryResult` (`optimistic`, `timestamp`)
- Added `lazy_cache_map.dart` for handling cyclical dereferences in the normalized cache
  - added `CacheState` for tracking optimism from the perspective of normalized cache entities
- Added `raw_operation_data.dart` to consolidate base functionality
- Added `rebroadcastQueries` to the `QueryManager`, for use post-update, which rebroadcasts all "safe" queries that can be with updated data from the cache
- Added `optimisticResult` management to the `QueryManager`
- Added `optimisticResult` to `BaseOptions`, and `QueryOptions` (it is added in `runMutation` for mutations)
- Added `optimistic` attribute `QueryResult` itself for lifecycle management.

#### Docs

- `LazyCacheMap` usage and reasoning
- Optimism section. differences between `result.optimistic` and `LazyCacheMap.isOptimistic`
- `update`, `onCompleted` usage/existence
- `refetch` usage/existence

## [1.0.0-beta.1+1] - February 16 2019

We are finally in BETA. This means we're one step closer to our first stable release.

Thanks to all the contributes.

Support GraphQL Upload spec as proposed at
https://github.com/jaydenseric/graphql-multipart-request-spec

### What's changed?

We have added a brand new `Link` that handles authentication. You can drop it in like so:

```dart
final HttpLink httpLink = HttpLink(
  uri: 'https://api.github.com/graphql',
);

final AuthLink authLink = AuthLink(
  getToken: () async => 'Bearer $YOUR_PERSONAL_ACCESS_TOKEN',
);

final Link link = authLink.concat(httpLink);

GraphQLClient client = GraphQLClient(
  cache: NormalizedInMemoryCache(
    dataIdFromObject: typenameDataIdFromObject,
  ),
  link: link,
);
```

The `getToken` function will be called right before each event gets passed to the next link. It set the `Authorization` header to the value returned by `getToken` and passes it under the `header` map to the context.

#### Breaking changes

n/a

#### Fixes / Enhancements

- Fixed decouple mutation side effects from component (#114). @micimize
- Fixed `data == {}` was always false, instead of `data.isEmpty`. @nesger
- Added `update(cache, result)` attribute to `Mutation`. @micimize
- Added `NormalizationException` to handle infinite dereference StackOverflow due to user error. @micimize
- Added the GraphQL message type `GQL_CONNECTION_KEEP_ALIVE`, so it isn't interpreted as `UnknownData` anymore. @ArneSchulze
- Added the brand ne `AuthLink` class. @HofmannZ
- Update example to use `NormalizedCache` / test decoupling by replacing the `Mutation` while in flight. @micimize
- Removed closed observable queries from `QueryManager`. @micimize

#### Docs

- Fixed typos. @xtian
- Added `MessageType` constant `GQL_CONNECTION_KEEP_ALIVE`. @ArneSchulze
- Added `GraphQLSocketMessage` class `ConnectionKeepAlive`. @ArneSchulze
- Added `Stream<ConnectionKeepAlive>` to `GraphQLSocket`. @ArneSchulze
- Updated the example to use the new AuthLink. @HofmannZ

## [1.0.0-alpha.11] - October 28 2018

### Breaking changes

n/a

#### Fixes / Enhancements

- Added `NormalizedInMemoryCache` as a new cache option. @micimize
- Fixed `Mutation` calling `onCompleted` for loading state. @rafaelring
- Fix type annotations. @HofmannZ
- Fixed http versions. @HofmannZ

#### Docs

- Added docs for the new `NormalizedInMemoryCache` option. @micimize
- Added @rafaelring as a contributor. @HofmannZ

## [1.0.0-alpha.10] - October 6 2018

### Breaking changes

n/a

#### Fixes / Enhancements

- Fixed `Query` variables not updating in the query. @micimize
- Fixed `Mutation` widget's behavior to properly set loading status. @Igor1201

#### Docs

- Added @micimize as a contributor. @HofmannZ
- Added @Igor1201 as a contributor. @HofmannZ

## [1.0.0-alpha.9] - September 25 2018

### Breaking changes

n/a

#### Fixes / Enhancements

- Fixed connectivity errors not being thrown and streamed. @HofmannZ

#### Docs

n/a

## [1.0.0-alpha.8] - September 21 2018

### Breaking changes

n/a

#### Fixes / Enhancements

- Removed an unused class. @HofmannZ
- Formatted the query manger. @HofmannZ
- Handle charset encoding in responses @kolja-esders

#### Docs

- Added some inline docs to Query widget. @HofmannZ
- Improved the inline docs of the client. @HofmannZ
- Update the example. @HofmannZ

## [1.0.0-alpha.7] - September 14 2018

### Breaking changes

n/a

#### Fixes / Enhancements

- Fixed a bug where getting the operation name was always returning null. @HofmannZ
- Override the fetch policy if the default query option is used. @HofmannZ
- Split up fetching and polling in the observable query. @HofmannZ
- Check if the stream is closed, before adding a new event to it. @HofmannZ
- Check if the variables have actually changed form or to null. @HofmannZ
- Added a new getter to check if a query result has errors. @HofmannZ
- Refactored the scheduler to only handle polling queries. @HofmannZ
- Updated the mutation widget to use the new api in observable query. @HofmannZ
- Resolve type cast exception when handling GraphQL errors. @kolja-esders @HofmannZ
- Propagate GraphQL errors to caller instead of throwing network exception. @kolja-esders

#### Docs

n/a

## [1.0.0-alpha.6] - September 10 2018

### Breaking changes

n/a

#### Fixes / Enhancements

- Updated lint options in preparation for upcoming CI checks. @HofmannZ

#### Docs

n/a

## [1.0.0-alpha.5] - September 7 2018

### Breaking changes

n/a

#### Fixes / Enhancements

- Fixed a bug where the wrong key was selected from the context map. @HofmannZ
- Fixed a scenario where the dispose method was calling the `close` method on the `observableQuery` class which might not have been initialised yet. @HofmannZ
- Added the `onComplete` callback for the `Mutation` widget. @HofmannZ
- Added the `initPayload` as an optional parameter for the `connect` method on the `SocketClient` class. @lordgreg

#### Docs

- Added an example of optionally overriding http options trough the context. @HofmannZ
- Added @lordgreg as a contributor. @HofmannZ
- Updated the example with explicit type casting. @HofmannZ
- Updated the `Mutation` example with the new `onComplete` callback. @HofmannZ

## [1.0.0-alpha.4] - September 4 2018

### Breaking changes

n/a

#### Fixes / Enhancements

- Always return something from the `read` method in the cache class. @HofmannZ
- Only save to cache with certain fetch policies. @HofmannZ
- Throw an error when no data from network with certain fetch policies. @HofmannZ
- Added a document parser. @HofmannZ
- Added operation name from document to the operation. @HofmannZ
- Only create a new observable query if options have changed. @HofmannZ
- Add context to the links. @HofmannZ
- Parse context in the http link to update the config. @HofmannZ
- Change the type of context from dynamic to Map<String, dynamic. @HofmannZ

#### Docs

n/a

## [1.0.0-alpha.3] - September 2 2018

### Breaking changes

n/a

#### Fixes / Enhancements

- Reverted changes to the required Dart version. @HofmannZ
- Added missing return statsments. @HofmannZ

#### Docs

n/a

## [1.0.0-alpha.2] - September 2 2018

### Breaking changes

n/a

#### Fixes / Enhancements

- `GraphQLClient` now reads and writes data from the `Cache` based on the provided `FetchPolicy` option. @HofmannZ
- Implemented caching for data from `FetchResults`. @HofmannZ
- The library now tagets Dart version `>=2.1.0-dev.0.0 <3.0.0` as recomended by Flutter `0.6.0`. @HofmannZ
- Removed the old client from the library. @HofmannZ

#### Docs

- Document the new API. @HofmannZ
- Write an upgrade guide. @HofmannZ
- Clean up the example. @HofmannZ

## [1.0.0-alpha.1] - September 2 2018

### Breaking changes

- Renamed `Client` to `GraphQLClient` to avoid name collision with other packages. @HofmannZ
- Renamed `GraphqlProvider` to `GraphQLProvider` to align with new naming. @HofmannZ
- Renamed `GraphqlConsumer` to `GraphQLConsumer` to align with new naming. @HofmannZ
- Renamed `GQLError` to `GraphQLError` to align with new naming. @HofmannZ
- `GraphQLClient` requires a `Link` to passed into the constructor. @HofmannZ
- `GraphQLClient` no longer requires a `endPoint` or `apiToken` to be passed into the constructor. Instead you can provide it to the `Link`. @HofmannZ
- The `Query` and `Mutation` widgets are now `StreamBuilders`, there the api did change slightly. @HofmannZ

#### Fixes / Enhancements

- Improved typing throughout the library. @HofmannZ
- Queries are handled as streams of operations. @HofmannZ
- Added the `HttpLink` to handle requests using http. @HofmannZ
- `HttpLink` allows headers to be customised. @HofmannZ
- The api allows contributors to write their own custom links. @HofmannZ

#### Docs

- Implement the new link system in the example. @HofmannZ

## [0.9.3] - September 5 2018

### Breaking changes

n/a

#### Fixes / Enhancements

- Fix wrong typedef causing runtime type mismatch. @HofmannZ

#### Docs

- Update the reference to the next branch. @HofmannZ

## [0.9.2] - 2 September 2018

### Breaking changes

n/a

#### Fixes / Enhancements

- Upgrade dependencies. @HofmannZ

#### Docs

- Added a refrence to our next major release. @HofmannZ

## [0.9.1] - August 30 2018

### Breaking changes

n/a

#### Fixes / Enhancements

- Move test dependency to the dev section. @fabiocarneiro
- Fix version resolving for test dependencies. @HofmannZ

#### Docs

n/a

## [0.9.0] - August 23 2018

### Breaking changes

n/a

#### Fixes / Enhancements

- Added error extensions support. @dustin-graham
- Changed the mutation typedef to return a Future, allowing async/await. @HofmannZ
- Fixed error handling when location is not provided. @adelcasse
- Fixed a bug where the client might no longer be in the same context. @HofmannZ

#### Docs

n/a

## [0.8.0] - August 10 2018

### Breaking changes

n/a

#### Fixes / Enhancements

- Added basic error handeling for queries and mutations @mmadjer
- Added missing export for the `GraphqlConsumer` widget @AleksandarFaraj

#### Docs

n/a

## [0.7.1] - August 3 2018

### Breaking changes

n/a

#### Fixes / Enhancements

- Code formatting @HofmannZ

#### Docs

- Updated the package description @HofmannZ

## [0.7.0] - July 22 2018

### Breaking changes

n/a

#### Fixes / Enhancements

- Added support for subsciptions in the client. @cal-pratt
- Added the `Subscription` widget. You can no direcly acces streams from Flutter. @cal-pratt

#### Docs

- Added instructions for adding subscripton to your poject. @cal-pratt
- Updated the `About this project` section. @HofmannZ

## [0.6.0] - July 19 2018

### Breaking changes

- The library now requires your app to be wrapped with the `GraphqlProvider` widget. @HofmannZ
- The global `client` variable is no longer available. Instead use the `GraphqlConsumer` widget. @HofmannZ

#### Fixes / Enhancements

- Added the `GraphqlProvider` widget. The client is now stored in an `InheritedWidget`, and can be accessed anywhere within the app. @HofmannZ

```dart
Client client = GraphqlProvider.of(context).value;
```

- Added the `GraphqlConsumer` widget. For ease of use we added a widget that uses the same builder structure as the `Query` and `Mutation` widgets. @HofmannZ

> Under the hood it access the client from the `BuildContext`.

- Added the option to optionally provide the `apiToken` to the `Client` constructor. It is still possible to set the `apiToken` with setter method. @HofmannZ

```dart
  return new GraphqlConsumer(
    builder: (Client client) {
      // do something with the client

      return new Container();
    },
  );
```

#### Docs

- Added documentation for the new `GraphqlProvider` @HofmannZ
- Added documentation for the new `GraphqlConsumer` @HofmannZ
- Changed the setup instructions to include the new widgets @HofmannZ
- Changed the example to include the new widgets @HofmannZ

## [0.5.4] - July 17 2018

### Breaking changes

n/a

#### Fixes / Enhancements

- Query: changed `Timer` to `Timer.periodic` @eusdima
- Minor logic tweak @eusdima
- Use absolute paths in the library @HofmannZ

#### Docs

- Fix mutations example bug not updating star bool @cal-pratt

## [0.5.3] - July 13 2018

### Breaking changes

n/a

#### Fixes / Enhancements

- Added polling timer as a variable for easy deletion on dispose
- Fixed bug when Query timer is still active when the Query is disposed
- Added instant query fetch when the query variables are updated

#### Docs

n/a

## [0.5.2] - July 11 2018

### Breaking changes

n/a

#### Fixes / Enhancements

- Fixed error when cache file is non-existent

#### Docs

n/a

## [0.5.1] - June 29 2018

### Breaking changes

n/a

#### Fixes / Enhancements

- Fixed json error parsing.

#### Docs

n/a

## [0.5.0] - June 25 2018

### Breaking changes

n/a

#### Fixes / Enhancements

- Introduced `onCompleted` callback for mutiations.
- Excluded some config files from version control.

#### Docs

- Fixed typos in the `readme.md`.
- The examples inculde an example of the `onCompleted` callback.

## [0.4.1] - June 22 2018

### Breaking changes

n/a

#### Fixes / Enhancements

n/a

#### Docs

- The examples now porperly reflect the changes to the library.

## [0.4.0] - June 21 2018

### Breaking changes

- The Client now requires a from of cache.
- The name of the `execute` method on the `Client` class changed to `query`.

#### Fixes / Enhancements

- Implemented in-memory cache.
- Write memory to file when in background.
- Added provider widget to save and restore the in-memory cache.
- Restructure the project.

#### Docs

- Update the `README.md` to refelct changes in the code.
- update the example to refelct changes in the code.

## [0.3.0] - June 16 2018

### Breaking changes

- Changed data type to `Map` instaid of `Object` to be more explicit.

#### Fixes / Enhancements

- Cosmatic changes.

#### Docs

- Added a Flutter app example.
- Fixed the example in `README.md`.
- Added more badges.

## [0.2.0] - June 15 2018

### Breaking changes

- Changed query widget `polling` argument to `pollInterval`, following the [react-apollo](https://github.com/apollographql/react-apollo) api.

#### Fixes / Enhancements

- Query polling is now optional.

#### Docs

- Updated the docs with the changes in api.

## [0.1.0] - June 15 2018

My colleague and I created a simple implementation of a GraphQL Client for Flutter. (Many thanks to Eus Dima, for his work on the initial client.)

### Breaking changes

n/a

#### Fixes / Enhancements

- A client to connect to your GraphQL server.
- A query widget to handle GraphQL queries.
- A mutation widget to handle GraphQL mutations.
- Simple support for query polling.

#### Docs

- Initial documentation.
