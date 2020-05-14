# v4 Dev Notes

## Differences between ferry_cache and graphql cache

- The old cache was layered, ferry_cache is stream-based
- The ferry_cache api accepts optimistic as a parameter, whereas the old cache attached optimism info to the response data

once you serialize the query request,
if you have to deserialize the cache update, you have no access to the callback

update cache handlers are applied twice – optimistically then from network

handling network failure more flexibility
possibly annotations

optimism handled by proxy

codegen difference

lean on hive

building on top of ferry client and cleint generator that would make the graphql api discovery easier
`client.queryName`
creating queries at build/runtime
limitation

- fragments as a unit of composition

single query controller which is a stream controller,
to make a query you add an event and the response stream picks it up

since all queries are added to the same stream controller,
pagination works by taking multiple data events and running user defined update

you can give mutations the same fetch policies

queries, mutations and subscriptions all run through the same controller


note: contribute better error messages on `operationName != operation.name` to normalize
