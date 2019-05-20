See [GitHub Releases](https://github.com/zino-app/graphql-flutter/releases).

* Loosened `initPayload` to `dynamic` to support many use-cases,
  Removed `InitOperation`'s excessive and inconsistent json encoding.
  Old implmentation can still be utilized as `legacyInitPayload`
  until deprecation

* Fixed broken anonymous operations
