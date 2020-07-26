import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:graphql/client.dart';
import 'package:meta/meta.dart';
import 'package:graphql/internal.dart';

import 'event.dart';
import 'state.dart';

abstract class GraphqlBloc<T> extends Bloc<GraphqlEvent<T>, GraphqlState<T>> {
  GraphQLClient client;
  ObservableQuery result;
  WatchQueryOptions options;

  GraphqlBloc({@required this.client, @required this.options})
      : super(GraphqlInitialState<T>()) {
    result = client.watchQuery(options);

    result.stream.listen((QueryResult result) {
      if (state is GraphqlRefetchState &&
          result.source == QueryResultSource.Cache) {
        return;
      }

      if (result.loading && result.data == null) {
        add(GraphqlLoadingEvent<T>(result: result));
      }

      if (!result.loading && result.data != null) {
        add(
          GraphqlLoadedEvent<T>(
            data: parseData(result.data as Map<String, dynamic>),
            result: result,
          ),
        );
      }

      if (result.hasException) {
        add(GraphqlErrorEvent<T>(error: result.exception, result: result));
      }
    });
  }

  void dispose() {
    result.close();
  }

  void run() {
    add(GraphqlRunQueryEvent<T>());
  }

  void refetch() {
    add(GraphqlRefetchEvent<T>());
  }

  bool shouldFetchMore(int i, int threshold) => false;

  bool get isFetchingMore => state is GraphqlFetchMoreState;

  bool get isLoading => state is GraphqlLoadingState;

  bool get isRefetching => state is GraphqlRefetchState;

  T parseData(Map<String, dynamic> data);

  bool get hasData => (state is GraphqlLoadedState<T> ||
      state is GraphqlFetchMoreState<T> ||
      state is GraphqlRefetchState<T>);

  bool get hasError => state is GraphqlErrorState<T>;

  String get getError => hasError
      ? parseOperationException((state as GraphqlErrorState<T>).error)
      : null;

  Future<void> _runQuery() async {
    result.fetchResults();
  }

  void _fetchMore(FetchMoreOptions options) {
    result.fetchMore(options);
  }

  void _refetch() => result.refetch();

  @override
  Stream<GraphqlState<T>> mapEventToState(GraphqlEvent<T> event) async* {
    if (event is GraphqlRunQueryEvent<T>) {
      _runQuery();
    }

    if (event is GraphqlLoadingEvent<T>) {
      yield GraphqlLoadingState<T>(result: event.result);
    }

    if (event is GraphqlLoadedEvent<T>) {
      yield GraphqlLoadedState<T>(data: event.data, result: event.result);
    }

    if (event is GraphqlErrorEvent<T>) {
      yield GraphqlErrorState<T>(error: event.error, result: event.result);
    }

    if (event is GraphqlRefetchEvent<T>) {
      yield GraphqlRefetchState<T>(data: state.data, result: null);
      _refetch();
    }

    if (state is GraphqlLoadedState && event is GraphqlFetchMoreEvent<T>) {
      yield GraphqlFetchMoreState<T>(data: state.data, result: null);
      _fetchMore(event.options);
    }
  }
}

String parseOperationException(OperationException error) {
  if (error.clientException != null) {
    final exception = error.clientException;

    if (exception is NetworkException) {
      return 'Failed to connect to ${exception.uri}';
    } else {
      return exception.toString();
    }
  }

  if (error.graphqlErrors != null && error.graphqlErrors.isNotEmpty) {
    final errors = error.graphqlErrors;

    return errors.first.message;
  }

  return 'Unknown error';
}
