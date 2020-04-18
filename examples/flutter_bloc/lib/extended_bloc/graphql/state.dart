import 'package:graphql/client.dart';
import 'package:meta/meta.dart';

abstract class GraphqlState<T> {
  final T data;

  const GraphqlState({@required this.data});
}

class GraphqlLoading<T> extends GraphqlState<T> {}

class GraphqlErrorState<T> extends GraphqlState<T> {
  final OperationException error;
  final QueryResult result;

  GraphqlErrorState({@required this.error, @required this.result})
      : super(data: null);
}

class GraphqlLoaded<T> extends GraphqlState<T> {
  final QueryResult result;

  GraphqlLoaded({@required T data, @required this.result}) : super(data: data);
}

class GraphqlRefetchState<T> extends GraphqlState<T> {
  final QueryResult result;

  GraphqlRefetchState({@required T data, @required this.result})
      : super(data: data);
}

class GraphqlFetchMoreState<T> extends GraphqlState<T> {
  final QueryResult result;

  GraphqlFetchMoreState({@required T data, @required this.result})
      : super(data: data);
}
