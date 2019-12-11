# Migrating from v2 – v3

## Replace `document` with `documentNode`

We are deprecating the `document` property from both QueryOptions and
MutationOptions, and will be completely removed from the API in the future.
Instead we encourage you to switch to `documentNode` which is [AST](https://pub.dev/packages/gql) based.

**Before:**

```dart
const int nRepositories = 50;

final QueryOptions options = QueryOptions(
    document: readRepositories,
    variables: <String, dynamic>{
        'nRepositories': nRepositories,
    },
);
```

**After:**

```dart
const int nRepositories = 50;

final QueryOptions options = QueryOptions(
    documentNode: gql(readRepositories),
    variables: <String, dynamic>{
        'nRepositories': nRepositories,
    },
);
```

## Error Handling - exception replaces error

Replace `results.error` with `results.exception`

**Before:**

```dart
final QueryResult result = await _client.query(options);

if (result.hasError) {
    print(result.error.toString());
}
...

```

**After:**

```dart
final QueryResult result = await _client.query(options);

if (result.hasException) {
    print(result.exception.toString());
}
...

```

## Mutation Callbacks have been Moved to `MutationOptions`

Mutation options have been moved to `MutationOptions` from the `Mutation` widget.

**Before:**

```dart
Mutation(
  options: MutationOptions(
    document: addStar,
  ),
  builder: (
    RunMutation runMutation,
    QueryResult result,
  ) {
    return FloatingActionButton(
      onPressed: () => runMutation({
        'starrableId': <A_STARTABLE_REPOSITORY_ID>,
      }),
      tooltip: 'Star',
      child: Icon(Icons.star),
    );
  },
  update: (Cache cache, QueryResult result) {
    return cache;
  },
  onCompleted: (dynamic resultData) {
    print(resultData);
  },
);

...
```

**After:**

```dart

...

Mutation(
  options: MutationOptions(
    documentNode: gql(addStar), 
    update: (Cache cache, QueryResult result) {
      return cache;
    },
    onCompleted: (dynamic resultData) {
      print(resultData);
    },
  ),
  builder: (
    RunMutation runMutation,
    QueryResult result,
  ) {
    return FloatingActionButton(
      onPressed: () => runMutation({
        'starrableId': <A_STARTABLE_REPOSITORY_ID>,
      }),
      tooltip: 'Star',
      child: Icon(Icons.star),
    );
  },
);

...

```
