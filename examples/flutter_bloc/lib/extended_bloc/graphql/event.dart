import 'package:graphql/client.dart';
import 'package:meta/meta.dart';

abstract class GraphqlEvent<T> {}

class GraphqlErrorEvent<T> extends GraphqlEvent<T> {
  final OperationException error;
  final QueryResult result;

  GraphqlErrorEvent({@required this.error, @required this.result});
}

class GraphqlLoadedEvent<T> extends GraphqlEvent<T> {
  final T data;
  final QueryResult result;

  GraphqlLoadedEvent({@required this.data, @required this.result});
}

class GraphqlRefetchEvent<T> extends GraphqlEvent<T> {}

class GraphqlFetchMoreEvent<T> extends GraphqlEvent<T> {
  final FetchMoreOptions options;

  GraphqlFetchMoreEvent({@required this.options});
}
