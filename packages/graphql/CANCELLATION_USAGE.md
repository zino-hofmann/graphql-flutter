# Cancellation Support

The graphql package now supports cancellation of `query` and `mutate` operations. This allows you to cancel in-flight operations when they're no longer needed (e.g., when a user navigates away or cancels an action).

## Basic Usage

### Option 1: Using CancellationToken directly

```dart
import 'package:graphql/client.dart';

// Create a cancellation token
final cancellationToken = CancellationToken();

// Execute a query with the cancellation token
final resultFuture = client.query(
  QueryOptions(
    document: gql(r'''
      query GetUser($id: ID!) {
        user(id: $id) {
          id
          name
          email
        }
      }
    '''),
    variables: {'id': '123'},
    cancellationToken: cancellationToken,
  ),
);

// Later, if you need to cancel the operation:
cancellationToken.cancel();

// The resultFuture will complete with a QueryResult containing
// a CancelledException
try {
  final result = await resultFuture;
  print('Result: ${result.data}');
} catch (e) {
  if (e is OperationException && 
      e.linkException is CancelledException) {
    print('Operation was cancelled');
  }
}

// Don't forget to dispose the token when done
cancellationToken.dispose();
```

### Option 2: Using the convenience methods

The package provides `queryCancellable` and `mutateCancellable` convenience methods that automatically create a `CancellationToken` for you:

```dart
import 'package:graphql/client.dart';

// Execute a cancellable query
final operation = client.queryCancellable(
  QueryOptions(
    document: gql(r'''
      query GetPosts {
        posts {
          id
          title
          content
        }
      }
    '''),
  ),
);

// Access the result future
final resultFuture = operation.result;

// Cancel the operation if needed
operation.cancel();

// Handle the result
try {
  final result = await resultFuture;
  print('Posts: ${result.data}');
} catch (e) {
  if (e is OperationException && 
      e.linkException is CancelledException) {
    print('Query was cancelled');
  }
}
```

## Mutation Example

```dart
import 'package:graphql/client.dart';

// Execute a cancellable mutation
final operation = client.mutateCancellable(
  MutationOptions(
    document: gql(r'''
      mutation CreatePost($title: String!, $content: String!) {
        createPost(title: $title, content: $content) {
          id
          title
          content
        }
      }
    '''),
    variables: {
      'title': 'New Post',
      'content': 'This is the content',
    },
  ),
);

// Cancel if user navigates away
// operation.cancel();

try {
  final result = await operation.result;
  print('Created post: ${result.data}');
} catch (e) {
  if (e is OperationException && 
      e.linkException is CancelledException) {
    print('Mutation was cancelled');
  }
}
```

## Use Cases

### 1. User Navigation
Cancel pending requests when a user navigates away from a page:

```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  CancellableOperation<QueryResult>? _operation;

  @override
  void initState() {
    super.initState();
    _operation = client.queryCancellable(
      QueryOptions(document: gql('query { ... }')),
    );
  }

  @override
  void dispose() {
    // Cancel the operation when the widget is disposed
    _operation?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _operation?.result,
      builder: (context, snapshot) {
        // Build your UI
      },
    );
  }
}
```

### 2. Search Debouncing
Cancel previous search requests when a new one is initiated:

```dart
CancellableOperation<QueryResult>? _searchOperation;

void search(String query) {
  // Cancel the previous search
  _searchOperation?.cancel();

  // Start a new search
  _searchOperation = client.queryCancellable(
    QueryOptions(
      document: gql(r'''
        query Search($query: String!) {
          search(query: $query) {
            id
            name
          }
        }
      '''),
      variables: {'query': query},
    ),
  );

  _searchOperation!.result.then((result) {
    // Handle search results
  }).catchError((e) {
    if (e is OperationException && 
        e.linkException is CancelledException) {
      // Search was cancelled, ignore
      return;
    }
    // Handle other errors
  });
}
```

### 3. Timeout with Custom Message
Combine with timeouts for better control:

```dart
final cancellationToken = CancellationToken();

// Set a custom timeout
Timer(Duration(seconds: 10), () {
  cancellationToken.cancel();
});

final result = await client.query(
  QueryOptions(
    document: gql('query { ... }'),
    cancellationToken: cancellationToken,
  ),
);
```

## Important Notes

1. **Disposing CancellationTokens**: When using `CancellationToken` directly, remember to call `dispose()` when you're done with it to clean up resources.

2. **Convenience Methods**: The `queryCancellable` and `mutateCancellable` methods automatically create and manage `CancellationToken` instances for you.

3. **Error Handling**: Cancelled operations will complete with an `OperationException` containing a `CancelledException` as the `linkException`.

4. **Network Cleanup**: Cancelling an operation will attempt to cancel the underlying network request, but depending on the transport layer and server, the request may still complete on the server side.

5. **Cache Updates**: Cancelled operations will not update the cache with any results they may have received before cancellation.
