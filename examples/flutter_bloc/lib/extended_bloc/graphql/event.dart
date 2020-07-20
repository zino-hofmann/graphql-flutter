import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:graphql/client.dart';
import 'package:meta/meta.dart';

part 'event.freezed.dart';

abstract class GraphqlEvent<T> {}

@freezed
abstract class GraphqlErrorEvent<T> extends GraphqlEvent<T>
    implements _$GraphqlErrorEvent<T> {
  GraphqlErrorEvent._();

  factory GraphqlErrorEvent({
    @required OperationException error,
    @required QueryResult result,
  }) = _GraphqlErrorEvent<T>;
}

@freezed
abstract class GraphqlRunQueryEvent<T> extends GraphqlEvent<T>
    implements _$GraphqlRunQueryEvent<T> {
  GraphqlRunQueryEvent._();

  factory GraphqlRunQueryEvent() = _GraphqlRunQueryEvent<T>;
}

@freezed
abstract class GraphqlLoadingEvent<T> extends GraphqlEvent<T>
    implements _$GraphqlLoadingEvent<T> {
  GraphqlLoadingEvent._();

  factory GraphqlLoadingEvent({
    @required QueryResult result,
  }) = _GraphqlLoadingEvent<T>;
}

@freezed
abstract class GraphqlLoadedEvent<T> extends GraphqlEvent<T>
    implements _$GraphqlLoadedEvent<T> {
  GraphqlLoadedEvent._();

  factory GraphqlLoadedEvent({@required T data, @required QueryResult result}) =
      _GraphqlLoadedEvent<T>;
}

@freezed
abstract class GraphqlRefetchEvent<T> extends GraphqlEvent<T>
    implements _$GraphqlRefetchEvent<T> {
  GraphqlRefetchEvent._();

  factory GraphqlRefetchEvent() = _GraphqlRefetchEvent<T>;
}

@freezed
abstract class GraphqlFetchMoreEvent<T> extends GraphqlEvent<T>
    implements _$GraphqlFetchMoreEvent<T> {
  GraphqlFetchMoreEvent._();

  factory GraphqlFetchMoreEvent({
    @required FetchMoreOptions options,
  }) = _GraphqlFetchMoreEvent<T>;
}
