import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:graphql/client.dart';
import 'package:meta/meta.dart';

part 'state.freezed.dart';

abstract class GraphqlState<T> {
  final T data;

  const GraphqlState({@required this.data});
}

@freezed
abstract class GraphqlInitialState<T> extends GraphqlState<T>
    implements _$GraphqlInitialState<T> {
  GraphqlInitialState._();

  factory GraphqlInitialState() = _GraphqlInitialState<T>;
}

@freezed
abstract class GraphqlLoadingState<T> extends GraphqlState<T>
    implements _$GraphqlLoadingState<T> {
  GraphqlLoadingState._();

  factory GraphqlLoadingState({
    @required QueryResult result,
  }) = _GraphqlLoadingState<T>;
}

@freezed
abstract class GraphqlErrorState<T> extends GraphqlState<T>
    implements _$GraphqlErrorState<T> {
  GraphqlErrorState._();

  factory GraphqlErrorState(
      {@required OperationException error,
      @required QueryResult result}) = _GraphqlErrorState<T>;
}

@freezed
abstract class GraphqlLoadedState<T> extends GraphqlState<T>
    implements _$GraphqlLoadedState<T> {
  GraphqlLoadedState._();

  factory GraphqlLoadedState({@required T data, @required QueryResult result}) =
      _GraphqlLoadedState<T>;
}

@freezed
abstract class GraphqlRefetchState<T> extends GraphqlState<T>
    implements _$GraphqlRefetchState<T> {
  GraphqlRefetchState._();

  factory GraphqlRefetchState({
    @required T data,
    QueryResult result,
  }) = _GraphqlRefetchState<T>;
}

@freezed
abstract class GraphqlFetchMoreState<T> extends GraphqlState<T>
    implements _$GraphqlFetchMoreState<T> {
  GraphqlFetchMoreState._();

  factory GraphqlFetchMoreState({
    @required T data,
    QueryResult result,
  }) = _GraphqlFetchMoreState<T>;
}
