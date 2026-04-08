# Cancellation Support

The graphql package now supports cancellation of `query` and `mutate`
operations. This allows you to cancel in-flight operations when they're no
longer needed (e.g., when a user navigates away or cancels an action).

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

The package provides `queryCancellable` and `mutateCancellable` convenience
methods that automatically create a `CancellationToken` for you:

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

1. **Disposing CancellationTokens**: When using `CancellationToken` directly,
   remember to call `dispose()` when you're done with it to clean up resources.

2. **Convenience Methods**: The `queryCancellable` and `mutateCancellable`
   methods automatically create and manage `CancellationToken` instances for
   you.

3. **Error Handling**: Cancelled operations will complete with an
   `OperationException` containing a `CancelledException` as the
   `linkException`.

4. **Network Behavior**: By default (with the standard `HttpLink` from
   `gql_http_link`), cancellation happens at the QueryManager level - the HTTP
   request still completes but the response is ignored. If you need true
   HTTP-level cancellation (where the request actually aborts and shows as
   "(canceled)" in browser DevTools), use `CancellableHttpLink` instead.

5. **Cache Updates**: Cancelled operations will not update the cache with any
   results they may have received before cancellation.

## HTTP-Level Cancellation with CancellableHttpLink

For true HTTP-level cancellation where the underlying network request is
actually aborted, use `CancellableHttpLink` instead of the standard `HttpLink`:

```dart
import 'package:graphql/client.dart';

// Use CancellableHttpLink instead of HttpLink
final link = CancellableHttpLink('https://api.example.com/graphql');

final client = GraphQLClient(
  cache: GraphQLCache(),
  link: link,
);

// Now cancellations will actually abort the HTTP request
final operation = client.queryCancellable(
  QueryOptions(
    document: gql('query { ... }'),
    fetchPolicy: FetchPolicy.networkOnly,
  ),
);

operation.cancel(); // Actually cancels the HTTP request!
```

### CancellableHttpLink Features

- **True HTTP Cancellation**: On web, uses `XMLHttpRequest.abort()`. On IO,
  uses `HttpClientRequest.abort()`.
- **Full Feature Parity**: Supports all the same features as `HttpLink`
  including file uploads (multipart requests), GET queries, custom headers.
- **Connection Pooling**: Uses a shared `HttpClient` on IO for efficient
  connection reuse.
- **DevTools Visibility**: Cancelled requests show as "(canceled)" in browser
  DevTools Network tab.

### When to Use CancellableHttpLink

Use `CancellableHttpLink` when:
- You want cancelled requests to free up network resources immediately
- You need to see cancellation status in browser DevTools
- You're making many requests that may be cancelled (e.g., search-as-you-type)

Use the standard `HttpLink` when:
- Cancellation is rare and network overhead isn't a concern
- You need features that require a custom `http.Client`
- You want to use an existing `HttpLink` configuration

### Known Limitations

- **Cancellation Detection**: CancellableHttpLink detects cancellation by
  checking if `http.ClientException.message` contains 'cancelled' or 'abort'.
  In the extremely rare case that a legitimate network error contains these
  words, it would be incorrectly reported as a `CancelledException`. This is
  necessary because the HTTP package doesn't provide a specific exception type
  for aborted requests.
