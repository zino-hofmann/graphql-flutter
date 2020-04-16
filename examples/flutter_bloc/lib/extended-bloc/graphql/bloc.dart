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

  GraphqlBloc({this.client, @required this.options}) {
    result = client.watchQuery(options);

    result.stream.listen((QueryResult result) {
      if (!result.loading && result.data != null) {
        add(
          GraphqlLoadedEvent<T>(
            data: parseData(result.data as Map<String, dynamic>),
            result: result,
          ),
        );
      }

      if (result.hasException) {
        add(GraphqlErrorEvent(error: result.exception, result: result));
      }
    });

    _runQuery();
  }

  void dispose() {
    result.close();
  }

  T parseData(Map<String, dynamic> data);

  Future<void> _runQuery() async {
    result.fetchResults();
  }

  void _fetchMore(FetchMoreOptions options) {
    result.fetchMore(options);
  }

  void _refetch() => result.refetch();

  @override
  GraphqlState<T> get initialState => GraphqlLoading<T>();

  @override
  Stream<GraphqlState<T>> mapEventToState(GraphqlEvent<T> event) async* {
    if (event is GraphqlLoadedEvent<T>) {
      yield GraphqlLoaded<T>(data: event.data, result: event.result);
    }

    if (event is GraphqlErrorEvent<T>) {
      yield GraphqlErrorState<T>(error: event.error, result: event.result);
    }

    if (event is GraphqlRefetchEvent<T>) {
      yield GraphqlRefetchState<T>(data: state.data, result: null);
      _refetch();
    }

    if (state is GraphqlLoaded && event is GraphqlFetchMoreEvent<T>) {
      yield GraphqlFetchMoreState<T>(data: state.data, result: null);
      _fetchMore(event.options);
    }
  }
}
