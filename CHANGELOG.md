## [0.1.0] - June 15 2018

My colleague and I created a simple implementation of a GraphQL Client for Flutter. (Many thanks to Eus Dima, for his work on the initial client.)

### Breaking change

n/a

#### Fixes / Enhancements

- A client to connect to your GraphQL server.
- A query widget to handle GraphQL queries.
- A mutation widget to handle GraphQL mutations.
- Simple support for query polling.

#### Docs

- Initial documentation.

## [0.2.0] - June 15 2018

### Breaking change

- Changed query widget `polling` argument to `pollInterval`, following the [react-apollo](https://github.com/apollographql/react-apollo) api.

#### Fixes / Enhancements

- Query polling is now optional.

#### Docs

- Updated the docs with the changes in api.
