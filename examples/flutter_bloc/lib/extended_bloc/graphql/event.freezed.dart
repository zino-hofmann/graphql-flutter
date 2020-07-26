// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies

part of 'event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

class _$GraphqlErrorEventTearOff {
  const _$GraphqlErrorEventTearOff();

// ignore: unused_element
  _GraphqlErrorEvent<T> call<T>(
      {@required OperationException error, @required QueryResult result}) {
    return _GraphqlErrorEvent<T>(
      error: error,
      result: result,
    );
  }
}

// ignore: unused_element
const $GraphqlErrorEvent = _$GraphqlErrorEventTearOff();

mixin _$GraphqlErrorEvent<T> {
  OperationException get error;
  QueryResult get result;

  $GraphqlErrorEventCopyWith<T, GraphqlErrorEvent<T>> get copyWith;
}

abstract class $GraphqlErrorEventCopyWith<T, $Res> {
  factory $GraphqlErrorEventCopyWith(GraphqlErrorEvent<T> value,
          $Res Function(GraphqlErrorEvent<T>) then) =
      _$GraphqlErrorEventCopyWithImpl<T, $Res>;
  $Res call({OperationException error, QueryResult result});
}

class _$GraphqlErrorEventCopyWithImpl<T, $Res>
    implements $GraphqlErrorEventCopyWith<T, $Res> {
  _$GraphqlErrorEventCopyWithImpl(this._value, this._then);

  final GraphqlErrorEvent<T> _value;
  // ignore: unused_field
  final $Res Function(GraphqlErrorEvent<T>) _then;

  @override
  $Res call({
    Object error = freezed,
    Object result = freezed,
  }) {
    return _then(_value.copyWith(
      error: error == freezed ? _value.error : error as OperationException,
      result: result == freezed ? _value.result : result as QueryResult,
    ));
  }
}

abstract class _$GraphqlErrorEventCopyWith<T, $Res>
    implements $GraphqlErrorEventCopyWith<T, $Res> {
  factory _$GraphqlErrorEventCopyWith(_GraphqlErrorEvent<T> value,
          $Res Function(_GraphqlErrorEvent<T>) then) =
      __$GraphqlErrorEventCopyWithImpl<T, $Res>;
  @override
  $Res call({OperationException error, QueryResult result});
}

class __$GraphqlErrorEventCopyWithImpl<T, $Res>
    extends _$GraphqlErrorEventCopyWithImpl<T, $Res>
    implements _$GraphqlErrorEventCopyWith<T, $Res> {
  __$GraphqlErrorEventCopyWithImpl(
      _GraphqlErrorEvent<T> _value, $Res Function(_GraphqlErrorEvent<T>) _then)
      : super(_value, (v) => _then(v as _GraphqlErrorEvent<T>));

  @override
  _GraphqlErrorEvent<T> get _value => super._value as _GraphqlErrorEvent<T>;

  @override
  $Res call({
    Object error = freezed,
    Object result = freezed,
  }) {
    return _then(_GraphqlErrorEvent<T>(
      error: error == freezed ? _value.error : error as OperationException,
      result: result == freezed ? _value.result : result as QueryResult,
    ));
  }
}

class _$_GraphqlErrorEvent<T> extends _GraphqlErrorEvent<T> {
  _$_GraphqlErrorEvent({@required this.error, @required this.result})
      : assert(error != null),
        assert(result != null),
        super._();

  @override
  final OperationException error;
  @override
  final QueryResult result;

  @override
  String toString() {
    return 'GraphqlErrorEvent<$T>(error: $error, result: $result)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _GraphqlErrorEvent<T> &&
            (identical(other.error, error) ||
                const DeepCollectionEquality().equals(other.error, error)) &&
            (identical(other.result, result) ||
                const DeepCollectionEquality().equals(other.result, result)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(error) ^
      const DeepCollectionEquality().hash(result);

  @override
  _$GraphqlErrorEventCopyWith<T, _GraphqlErrorEvent<T>> get copyWith =>
      __$GraphqlErrorEventCopyWithImpl<T, _GraphqlErrorEvent<T>>(
          this, _$identity);
}

abstract class _GraphqlErrorEvent<T> extends GraphqlErrorEvent<T> {
  _GraphqlErrorEvent._() : super._();
  factory _GraphqlErrorEvent(
      {@required OperationException error,
      @required QueryResult result}) = _$_GraphqlErrorEvent<T>;

  @override
  OperationException get error;
  @override
  QueryResult get result;
  @override
  _$GraphqlErrorEventCopyWith<T, _GraphqlErrorEvent<T>> get copyWith;
}

class _$GraphqlRunQueryEventTearOff {
  const _$GraphqlRunQueryEventTearOff();

// ignore: unused_element
  _GraphqlRunQueryEvent<T> call<T>() {
    return _GraphqlRunQueryEvent<T>();
  }
}

// ignore: unused_element
const $GraphqlRunQueryEvent = _$GraphqlRunQueryEventTearOff();

mixin _$GraphqlRunQueryEvent<T> {}

abstract class $GraphqlRunQueryEventCopyWith<T, $Res> {
  factory $GraphqlRunQueryEventCopyWith(GraphqlRunQueryEvent<T> value,
          $Res Function(GraphqlRunQueryEvent<T>) then) =
      _$GraphqlRunQueryEventCopyWithImpl<T, $Res>;
}

class _$GraphqlRunQueryEventCopyWithImpl<T, $Res>
    implements $GraphqlRunQueryEventCopyWith<T, $Res> {
  _$GraphqlRunQueryEventCopyWithImpl(this._value, this._then);

  final GraphqlRunQueryEvent<T> _value;
  // ignore: unused_field
  final $Res Function(GraphqlRunQueryEvent<T>) _then;
}

abstract class _$GraphqlRunQueryEventCopyWith<T, $Res> {
  factory _$GraphqlRunQueryEventCopyWith(_GraphqlRunQueryEvent<T> value,
          $Res Function(_GraphqlRunQueryEvent<T>) then) =
      __$GraphqlRunQueryEventCopyWithImpl<T, $Res>;
}

class __$GraphqlRunQueryEventCopyWithImpl<T, $Res>
    extends _$GraphqlRunQueryEventCopyWithImpl<T, $Res>
    implements _$GraphqlRunQueryEventCopyWith<T, $Res> {
  __$GraphqlRunQueryEventCopyWithImpl(_GraphqlRunQueryEvent<T> _value,
      $Res Function(_GraphqlRunQueryEvent<T>) _then)
      : super(_value, (v) => _then(v as _GraphqlRunQueryEvent<T>));

  @override
  _GraphqlRunQueryEvent<T> get _value =>
      super._value as _GraphqlRunQueryEvent<T>;
}

class _$_GraphqlRunQueryEvent<T> extends _GraphqlRunQueryEvent<T> {
  _$_GraphqlRunQueryEvent() : super._();

  @override
  String toString() {
    return 'GraphqlRunQueryEvent<$T>()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) || (other is _GraphqlRunQueryEvent<T>);
  }

  @override
  int get hashCode => runtimeType.hashCode;
}

abstract class _GraphqlRunQueryEvent<T> extends GraphqlRunQueryEvent<T> {
  _GraphqlRunQueryEvent._() : super._();
  factory _GraphqlRunQueryEvent() = _$_GraphqlRunQueryEvent<T>;
}

class _$GraphqlLoadingEventTearOff {
  const _$GraphqlLoadingEventTearOff();

// ignore: unused_element
  _GraphqlLoadingEvent<T> call<T>({@required QueryResult result}) {
    return _GraphqlLoadingEvent<T>(
      result: result,
    );
  }
}

// ignore: unused_element
const $GraphqlLoadingEvent = _$GraphqlLoadingEventTearOff();

mixin _$GraphqlLoadingEvent<T> {
  QueryResult get result;

  $GraphqlLoadingEventCopyWith<T, GraphqlLoadingEvent<T>> get copyWith;
}

abstract class $GraphqlLoadingEventCopyWith<T, $Res> {
  factory $GraphqlLoadingEventCopyWith(GraphqlLoadingEvent<T> value,
          $Res Function(GraphqlLoadingEvent<T>) then) =
      _$GraphqlLoadingEventCopyWithImpl<T, $Res>;
  $Res call({QueryResult result});
}

class _$GraphqlLoadingEventCopyWithImpl<T, $Res>
    implements $GraphqlLoadingEventCopyWith<T, $Res> {
  _$GraphqlLoadingEventCopyWithImpl(this._value, this._then);

  final GraphqlLoadingEvent<T> _value;
  // ignore: unused_field
  final $Res Function(GraphqlLoadingEvent<T>) _then;

  @override
  $Res call({
    Object result = freezed,
  }) {
    return _then(_value.copyWith(
      result: result == freezed ? _value.result : result as QueryResult,
    ));
  }
}

abstract class _$GraphqlLoadingEventCopyWith<T, $Res>
    implements $GraphqlLoadingEventCopyWith<T, $Res> {
  factory _$GraphqlLoadingEventCopyWith(_GraphqlLoadingEvent<T> value,
          $Res Function(_GraphqlLoadingEvent<T>) then) =
      __$GraphqlLoadingEventCopyWithImpl<T, $Res>;
  @override
  $Res call({QueryResult result});
}

class __$GraphqlLoadingEventCopyWithImpl<T, $Res>
    extends _$GraphqlLoadingEventCopyWithImpl<T, $Res>
    implements _$GraphqlLoadingEventCopyWith<T, $Res> {
  __$GraphqlLoadingEventCopyWithImpl(_GraphqlLoadingEvent<T> _value,
      $Res Function(_GraphqlLoadingEvent<T>) _then)
      : super(_value, (v) => _then(v as _GraphqlLoadingEvent<T>));

  @override
  _GraphqlLoadingEvent<T> get _value => super._value as _GraphqlLoadingEvent<T>;

  @override
  $Res call({
    Object result = freezed,
  }) {
    return _then(_GraphqlLoadingEvent<T>(
      result: result == freezed ? _value.result : result as QueryResult,
    ));
  }
}

class _$_GraphqlLoadingEvent<T> extends _GraphqlLoadingEvent<T> {
  _$_GraphqlLoadingEvent({@required this.result})
      : assert(result != null),
        super._();

  @override
  final QueryResult result;

  @override
  String toString() {
    return 'GraphqlLoadingEvent<$T>(result: $result)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _GraphqlLoadingEvent<T> &&
            (identical(other.result, result) ||
                const DeepCollectionEquality().equals(other.result, result)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(result);

  @override
  _$GraphqlLoadingEventCopyWith<T, _GraphqlLoadingEvent<T>> get copyWith =>
      __$GraphqlLoadingEventCopyWithImpl<T, _GraphqlLoadingEvent<T>>(
          this, _$identity);
}

abstract class _GraphqlLoadingEvent<T> extends GraphqlLoadingEvent<T> {
  _GraphqlLoadingEvent._() : super._();
  factory _GraphqlLoadingEvent({@required QueryResult result}) =
      _$_GraphqlLoadingEvent<T>;

  @override
  QueryResult get result;
  @override
  _$GraphqlLoadingEventCopyWith<T, _GraphqlLoadingEvent<T>> get copyWith;
}

class _$GraphqlLoadedEventTearOff {
  const _$GraphqlLoadedEventTearOff();

// ignore: unused_element
  _GraphqlLoadedEvent<T> call<T>(
      {@required T data, @required QueryResult result}) {
    return _GraphqlLoadedEvent<T>(
      data: data,
      result: result,
    );
  }
}

// ignore: unused_element
const $GraphqlLoadedEvent = _$GraphqlLoadedEventTearOff();

mixin _$GraphqlLoadedEvent<T> {
  T get data;
  QueryResult get result;

  $GraphqlLoadedEventCopyWith<T, GraphqlLoadedEvent<T>> get copyWith;
}

abstract class $GraphqlLoadedEventCopyWith<T, $Res> {
  factory $GraphqlLoadedEventCopyWith(GraphqlLoadedEvent<T> value,
          $Res Function(GraphqlLoadedEvent<T>) then) =
      _$GraphqlLoadedEventCopyWithImpl<T, $Res>;
  $Res call({T data, QueryResult result});
}

class _$GraphqlLoadedEventCopyWithImpl<T, $Res>
    implements $GraphqlLoadedEventCopyWith<T, $Res> {
  _$GraphqlLoadedEventCopyWithImpl(this._value, this._then);

  final GraphqlLoadedEvent<T> _value;
  // ignore: unused_field
  final $Res Function(GraphqlLoadedEvent<T>) _then;

  @override
  $Res call({
    Object data = freezed,
    Object result = freezed,
  }) {
    return _then(_value.copyWith(
      data: data == freezed ? _value.data : data as T,
      result: result == freezed ? _value.result : result as QueryResult,
    ));
  }
}

abstract class _$GraphqlLoadedEventCopyWith<T, $Res>
    implements $GraphqlLoadedEventCopyWith<T, $Res> {
  factory _$GraphqlLoadedEventCopyWith(_GraphqlLoadedEvent<T> value,
          $Res Function(_GraphqlLoadedEvent<T>) then) =
      __$GraphqlLoadedEventCopyWithImpl<T, $Res>;
  @override
  $Res call({T data, QueryResult result});
}

class __$GraphqlLoadedEventCopyWithImpl<T, $Res>
    extends _$GraphqlLoadedEventCopyWithImpl<T, $Res>
    implements _$GraphqlLoadedEventCopyWith<T, $Res> {
  __$GraphqlLoadedEventCopyWithImpl(_GraphqlLoadedEvent<T> _value,
      $Res Function(_GraphqlLoadedEvent<T>) _then)
      : super(_value, (v) => _then(v as _GraphqlLoadedEvent<T>));

  @override
  _GraphqlLoadedEvent<T> get _value => super._value as _GraphqlLoadedEvent<T>;

  @override
  $Res call({
    Object data = freezed,
    Object result = freezed,
  }) {
    return _then(_GraphqlLoadedEvent<T>(
      data: data == freezed ? _value.data : data as T,
      result: result == freezed ? _value.result : result as QueryResult,
    ));
  }
}

class _$_GraphqlLoadedEvent<T> extends _GraphqlLoadedEvent<T> {
  _$_GraphqlLoadedEvent({@required this.data, @required this.result})
      : assert(data != null),
        assert(result != null),
        super._();

  @override
  final T data;
  @override
  final QueryResult result;

  @override
  String toString() {
    return 'GraphqlLoadedEvent<$T>(data: $data, result: $result)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _GraphqlLoadedEvent<T> &&
            (identical(other.data, data) ||
                const DeepCollectionEquality().equals(other.data, data)) &&
            (identical(other.result, result) ||
                const DeepCollectionEquality().equals(other.result, result)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(data) ^
      const DeepCollectionEquality().hash(result);

  @override
  _$GraphqlLoadedEventCopyWith<T, _GraphqlLoadedEvent<T>> get copyWith =>
      __$GraphqlLoadedEventCopyWithImpl<T, _GraphqlLoadedEvent<T>>(
          this, _$identity);
}

abstract class _GraphqlLoadedEvent<T> extends GraphqlLoadedEvent<T> {
  _GraphqlLoadedEvent._() : super._();
  factory _GraphqlLoadedEvent(
      {@required T data,
      @required QueryResult result}) = _$_GraphqlLoadedEvent<T>;

  @override
  T get data;
  @override
  QueryResult get result;
  @override
  _$GraphqlLoadedEventCopyWith<T, _GraphqlLoadedEvent<T>> get copyWith;
}

class _$GraphqlRefetchEventTearOff {
  const _$GraphqlRefetchEventTearOff();

// ignore: unused_element
  _GraphqlRefetchEvent<T> call<T>() {
    return _GraphqlRefetchEvent<T>();
  }
}

// ignore: unused_element
const $GraphqlRefetchEvent = _$GraphqlRefetchEventTearOff();

mixin _$GraphqlRefetchEvent<T> {}

abstract class $GraphqlRefetchEventCopyWith<T, $Res> {
  factory $GraphqlRefetchEventCopyWith(GraphqlRefetchEvent<T> value,
          $Res Function(GraphqlRefetchEvent<T>) then) =
      _$GraphqlRefetchEventCopyWithImpl<T, $Res>;
}

class _$GraphqlRefetchEventCopyWithImpl<T, $Res>
    implements $GraphqlRefetchEventCopyWith<T, $Res> {
  _$GraphqlRefetchEventCopyWithImpl(this._value, this._then);

  final GraphqlRefetchEvent<T> _value;
  // ignore: unused_field
  final $Res Function(GraphqlRefetchEvent<T>) _then;
}

abstract class _$GraphqlRefetchEventCopyWith<T, $Res> {
  factory _$GraphqlRefetchEventCopyWith(_GraphqlRefetchEvent<T> value,
          $Res Function(_GraphqlRefetchEvent<T>) then) =
      __$GraphqlRefetchEventCopyWithImpl<T, $Res>;
}

class __$GraphqlRefetchEventCopyWithImpl<T, $Res>
    extends _$GraphqlRefetchEventCopyWithImpl<T, $Res>
    implements _$GraphqlRefetchEventCopyWith<T, $Res> {
  __$GraphqlRefetchEventCopyWithImpl(_GraphqlRefetchEvent<T> _value,
      $Res Function(_GraphqlRefetchEvent<T>) _then)
      : super(_value, (v) => _then(v as _GraphqlRefetchEvent<T>));

  @override
  _GraphqlRefetchEvent<T> get _value => super._value as _GraphqlRefetchEvent<T>;
}

class _$_GraphqlRefetchEvent<T> extends _GraphqlRefetchEvent<T> {
  _$_GraphqlRefetchEvent() : super._();

  @override
  String toString() {
    return 'GraphqlRefetchEvent<$T>()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) || (other is _GraphqlRefetchEvent<T>);
  }

  @override
  int get hashCode => runtimeType.hashCode;
}

abstract class _GraphqlRefetchEvent<T> extends GraphqlRefetchEvent<T> {
  _GraphqlRefetchEvent._() : super._();
  factory _GraphqlRefetchEvent() = _$_GraphqlRefetchEvent<T>;
}

class _$GraphqlFetchMoreEventTearOff {
  const _$GraphqlFetchMoreEventTearOff();

// ignore: unused_element
  _GraphqlFetchMoreEvent<T> call<T>({@required FetchMoreOptions options}) {
    return _GraphqlFetchMoreEvent<T>(
      options: options,
    );
  }
}

// ignore: unused_element
const $GraphqlFetchMoreEvent = _$GraphqlFetchMoreEventTearOff();

mixin _$GraphqlFetchMoreEvent<T> {
  FetchMoreOptions get options;

  $GraphqlFetchMoreEventCopyWith<T, GraphqlFetchMoreEvent<T>> get copyWith;
}

abstract class $GraphqlFetchMoreEventCopyWith<T, $Res> {
  factory $GraphqlFetchMoreEventCopyWith(GraphqlFetchMoreEvent<T> value,
          $Res Function(GraphqlFetchMoreEvent<T>) then) =
      _$GraphqlFetchMoreEventCopyWithImpl<T, $Res>;
  $Res call({FetchMoreOptions options});
}

class _$GraphqlFetchMoreEventCopyWithImpl<T, $Res>
    implements $GraphqlFetchMoreEventCopyWith<T, $Res> {
  _$GraphqlFetchMoreEventCopyWithImpl(this._value, this._then);

  final GraphqlFetchMoreEvent<T> _value;
  // ignore: unused_field
  final $Res Function(GraphqlFetchMoreEvent<T>) _then;

  @override
  $Res call({
    Object options = freezed,
  }) {
    return _then(_value.copyWith(
      options:
          options == freezed ? _value.options : options as FetchMoreOptions,
    ));
  }
}

abstract class _$GraphqlFetchMoreEventCopyWith<T, $Res>
    implements $GraphqlFetchMoreEventCopyWith<T, $Res> {
  factory _$GraphqlFetchMoreEventCopyWith(_GraphqlFetchMoreEvent<T> value,
          $Res Function(_GraphqlFetchMoreEvent<T>) then) =
      __$GraphqlFetchMoreEventCopyWithImpl<T, $Res>;
  @override
  $Res call({FetchMoreOptions options});
}

class __$GraphqlFetchMoreEventCopyWithImpl<T, $Res>
    extends _$GraphqlFetchMoreEventCopyWithImpl<T, $Res>
    implements _$GraphqlFetchMoreEventCopyWith<T, $Res> {
  __$GraphqlFetchMoreEventCopyWithImpl(_GraphqlFetchMoreEvent<T> _value,
      $Res Function(_GraphqlFetchMoreEvent<T>) _then)
      : super(_value, (v) => _then(v as _GraphqlFetchMoreEvent<T>));

  @override
  _GraphqlFetchMoreEvent<T> get _value =>
      super._value as _GraphqlFetchMoreEvent<T>;

  @override
  $Res call({
    Object options = freezed,
  }) {
    return _then(_GraphqlFetchMoreEvent<T>(
      options:
          options == freezed ? _value.options : options as FetchMoreOptions,
    ));
  }
}

class _$_GraphqlFetchMoreEvent<T> extends _GraphqlFetchMoreEvent<T> {
  _$_GraphqlFetchMoreEvent({@required this.options})
      : assert(options != null),
        super._();

  @override
  final FetchMoreOptions options;

  @override
  String toString() {
    return 'GraphqlFetchMoreEvent<$T>(options: $options)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _GraphqlFetchMoreEvent<T> &&
            (identical(other.options, options) ||
                const DeepCollectionEquality().equals(other.options, options)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(options);

  @override
  _$GraphqlFetchMoreEventCopyWith<T, _GraphqlFetchMoreEvent<T>> get copyWith =>
      __$GraphqlFetchMoreEventCopyWithImpl<T, _GraphqlFetchMoreEvent<T>>(
          this, _$identity);
}

abstract class _GraphqlFetchMoreEvent<T> extends GraphqlFetchMoreEvent<T> {
  _GraphqlFetchMoreEvent._() : super._();
  factory _GraphqlFetchMoreEvent({@required FetchMoreOptions options}) =
      _$_GraphqlFetchMoreEvent<T>;

  @override
  FetchMoreOptions get options;
  @override
  _$GraphqlFetchMoreEventCopyWith<T, _GraphqlFetchMoreEvent<T>> get copyWith;
}
