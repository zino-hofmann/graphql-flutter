## [2.1.1-beta.5](https://github.com/zino-app/graphql-flutter/compare/v2.1.1-beta.4@beta...v2.1.1-beta.5@beta) (2019-12-11)


### Bug Fixes

* subscriptions reconnect ([c310db2](https://github.com/zino-app/graphql-flutter/commit/c310db280119a830915c864e68999321c5cd8f90))
* subscriptions reconnect ([fd8f3d1](https://github.com/zino-app/graphql-flutter/commit/fd8f3d1b650dae9a5e961787e4adff36b391f98b))

See [GitHub Releases](https://github.com/zino-app/graphql-flutter/releases).

* Loosened `initPayload` to `dynamic` to support many use-cases,
  Removed `InitOperation`'s excessive and inconsistent json encoding.
  Old implmentation can still be utilized as `legacyInitPayload`
  until deprecation

* Fixed broken anonymous operations
