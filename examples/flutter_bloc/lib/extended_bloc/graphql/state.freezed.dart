// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies

part of 'state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

class _$GraphqlInitialStateTearOff {
  const _$GraphqlInitialStateTearOff();

// ignore: unused_element
  _GraphqlInitialState<T> call<T>() {
    return _GraphqlInitialState<T>();
  }
}

// ignore: unused_element
const $GraphqlInitialState = _$GraphqlInitialStateTearOff();

mixin _$GraphqlInitialState<T> {}

abstract class $GraphqlInitialStateCopyWith<T, $Res> {
  factory $GraphqlInitialStateCopyWith(GraphqlInitialState<T> value,
          $Res Function(GraphqlInitialState<T>) then) =
      _$GraphqlInitialStateCopyWithImpl<T, $Res>;
}

class _$GraphqlInitialStateCopyWithImpl<T, $Res>
    implements $GraphqlInitialStateCopyWith<T, $Res> {
  _$GraphqlInitialStateCopyWithImpl(this._value, this._then);

  final GraphqlInitialState<T> _value;
  // ignore: unused_field
  final $Res Function(GraphqlInitialState<T>) _then;
}

abstract class _$GraphqlInitialStateCopyWith<T, $Res> {
  factory _$GraphqlInitialStateCopyWith(_GraphqlInitialState<T> value,
          $Res Function(_GraphqlInitialState<T>) then) =
      __$GraphqlInitialStateCopyWithImpl<T, $Res>;
}

class __$GraphqlInitialStateCopyWithImpl<T, $Res>
    extends _$GraphqlInitialStateCopyWithImpl<T, $Res>
    implements _$GraphqlInitialStateCopyWith<T, $Res> {
  __$GraphqlInitialStateCopyWithImpl(_GraphqlInitialState<T> _value,
      $Res Function(_GraphqlInitialState<T>) _then)
      : super(_value, (v) => _then(v as _GraphqlInitialState<T>));

  @override
  _GraphqlInitialState<T> get _value => super._value as _GraphqlInitialState<T>;
}

class _$_GraphqlInitialState<T> extends _GraphqlInitialState<T> {
  _$_GraphqlInitialState() : super._();

  @override
  String toString() {
    return 'GraphqlInitialState<$T>()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) || (other is _GraphqlInitialState<T>);
  }

  @override
  int get hashCode => runtimeType.hashCode;
}

abstract class _GraphqlInitialState<T> extends GraphqlInitialState<T> {
  _GraphqlInitialState._() : super._();
  factory _GraphqlInitialState() = _$_GraphqlInitialState<T>;
}

class _$GraphqlLoadingStateTearOff {
  const _$GraphqlLoadingStateTearOff();

// ignore: unused_element
  _GraphqlLoadingState<T> call<T>({@required QueryResult result}) {
    return _GraphqlLoadingState<T>(
      result: result,
    );
  }
}

// ignore: unused_element
const $GraphqlLoadingState = _$GraphqlLoadingStateTearOff();

mixin _$GraphqlLoadingState<T> {
  QueryResult get result;

  $GraphqlLoadingStateCopyWith<T, GraphqlLoadingState<T>> get copyWith;
}

abstract class $GraphqlLoadingStateCopyWith<T, $Res> {
  factory $GraphqlLoadingStateCopyWith(GraphqlLoadingState<T> value,
          $Res Function(GraphqlLoadingState<T>) then) =
      _$GraphqlLoadingStateCopyWithImpl<T, $Res>;
  $Res call({QueryResult result});
}

class _$GraphqlLoadingStateCopyWithImpl<T, $Res>
    implements $GraphqlLoadingStateCopyWith<T, $Res> {
  _$GraphqlLoadingStateCopyWithImpl(this._value, this._then);

  final GraphqlLoadingState<T> _value;
  // ignore: unused_field
  final $Res Function(GraphqlLoadingState<T>) _then;

  @override
  $Res call({
    Object result = freezed,
  }) {
    return _then(_value.copyWith(
      result: result == freezed ? _value.result : result as QueryResult,
    ));
  }
}

abstract class _$GraphqlLoadingStateCopyWith<T, $Res>
    implements $GraphqlLoadingStateCopyWith<T, $Res> {
  factory _$GraphqlLoadingStateCopyWith(_GraphqlLoadingState<T> value,
          $Res Function(_GraphqlLoadingState<T>) then) =
      __$GraphqlLoadingStateCopyWithImpl<T, $Res>;
  @override
  $Res call({QueryResult result});
}

class __$GraphqlLoadingStateCopyWithImpl<T, $Res>
    extends _$GraphqlLoadingStateCopyWithImpl<T, $Res>
    implements _$GraphqlLoadingStateCopyWith<T, $Res> {
  __$GraphqlLoadingStateCopyWithImpl(_GraphqlLoadingState<T> _value,
      $Res Function(_GraphqlLoadingState<T>) _then)
      : super(_value, (v) => _then(v as _GraphqlLoadingState<T>));

  @override
  _GraphqlLoadingState<T> get _value => super._value as _GraphqlLoadingState<T>;

  @override
  $Res call({
    Object result = freezed,
  }) {
    return _then(_GraphqlLoadingState<T>(
      result: result == freezed ? _value.result : result as QueryResult,
    ));
  }
}

class _$_GraphqlLoadingState<T> extends _GraphqlLoadingState<T> {
  _$_GraphqlLoadingState({@required this.result})
      : assert(result != null),
        super._();

  @override
  final QueryResult result;

  @override
  String toString() {
    return 'GraphqlLoadingState<$T>(result: $result)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _GraphqlLoadingState<T> &&
            (identical(other.result, result) ||
                const DeepCollectionEquality().equals(other.result, result)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(result);

  @override
  _$GraphqlLoadingStateCopyWith<T, _GraphqlLoadingState<T>> get copyWith =>
      __$GraphqlLoadingStateCopyWithImpl<T, _GraphqlLoadingState<T>>(
          this, _$identity);
}

abstract class _GraphqlLoadingState<T> extends GraphqlLoadingState<T> {
  _GraphqlLoadingState._() : super._();
  factory _GraphqlLoadingState({@required QueryResult result}) =
      _$_GraphqlLoadingState<T>;

  @override
  QueryResult get result;
  @override
  _$GraphqlLoadingStateCopyWith<T, _GraphqlLoadingState<T>> get copyWith;
}

class _$GraphqlErrorStateTearOff {
  const _$GraphqlErrorStateTearOff();

// ignore: unused_element
  _GraphqlErrorState<T> call<T>(
      {@required OperationException error, @required QueryResult result}) {
    return _GraphqlErrorState<T>(
      error: error,
      result: result,
    );
  }
}

// ignore: unused_element
const $GraphqlErrorState = _$GraphqlErrorStateTearOff();

mixin _$GraphqlErrorState<T> {
  OperationException get error;
  QueryResult get result;

  $GraphqlErrorStateCopyWith<T, GraphqlErrorState<T>> get copyWith;
}

abstract class $GraphqlErrorStateCopyWith<T, $Res> {
  factory $GraphqlErrorStateCopyWith(GraphqlErrorState<T> value,
          $Res Function(GraphqlErrorState<T>) then) =
      _$GraphqlErrorStateCopyWithImpl<T, $Res>;
  $Res call({OperationException error, QueryResult result});
}

class _$GraphqlErrorStateCopyWithImpl<T, $Res>
    implements $GraphqlErrorStateCopyWith<T, $Res> {
  _$GraphqlErrorStateCopyWithImpl(this._value, this._then);

  final GraphqlErrorState<T> _value;
  // ignore: unused_field
  final $Res Function(GraphqlErrorState<T>) _then;

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

abstract class _$GraphqlErrorStateCopyWith<T, $Res>
    implements $GraphqlErrorStateCopyWith<T, $Res> {
  factory _$GraphqlErrorStateCopyWith(_GraphqlErrorState<T> value,
          $Res Function(_GraphqlErrorState<T>) then) =
      __$GraphqlErrorStateCopyWithImpl<T, $Res>;
  @override
  $Res call({OperationException error, QueryResult result});
}

class __$GraphqlErrorStateCopyWithImpl<T, $Res>
    extends _$GraphqlErrorStateCopyWithImpl<T, $Res>
    implements _$GraphqlErrorStateCopyWith<T, $Res> {
  __$GraphqlErrorStateCopyWithImpl(
      _GraphqlErrorState<T> _value, $Res Function(_GraphqlErrorState<T>) _then)
      : super(_value, (v) => _then(v as _GraphqlErrorState<T>));

  @override
  _GraphqlErrorState<T> get _value => super._value as _GraphqlErrorState<T>;

  @override
  $Res call({
    Object error = freezed,
    Object result = freezed,
  }) {
    return _then(_GraphqlErrorState<T>(
      error: error == freezed ? _value.error : error as OperationException,
      result: result == freezed ? _value.result : result as QueryResult,
    ));
  }
}

class _$_GraphqlErrorState<T> extends _GraphqlErrorState<T> {
  _$_GraphqlErrorState({@required this.error, @required this.result})
      : assert(error != null),
        assert(result != null),
        super._();

  @override
  final OperationException error;
  @override
  final QueryResult result;

  @override
  String toString() {
    return 'GraphqlErrorState<$T>(error: $error, result: $result)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _GraphqlErrorState<T> &&
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
  _$GraphqlErrorStateCopyWith<T, _GraphqlErrorState<T>> get copyWith =>
      __$GraphqlErrorStateCopyWithImpl<T, _GraphqlErrorState<T>>(
          this, _$identity);
}

abstract class _GraphqlErrorState<T> extends GraphqlErrorState<T> {
  _GraphqlErrorState._() : super._();
  factory _GraphqlErrorState(
      {@required OperationException error,
      @required QueryResult result}) = _$_GraphqlErrorState<T>;

  @override
  OperationException get error;
  @override
  QueryResult get result;
  @override
  _$GraphqlErrorStateCopyWith<T, _GraphqlErrorState<T>> get copyWith;
}

class _$GraphqlLoadedStateTearOff {
  const _$GraphqlLoadedStateTearOff();

// ignore: unused_element
  _GraphqlLoadedState<T> call<T>(
      {@required T data, @required QueryResult result}) {
    return _GraphqlLoadedState<T>(
      data: data,
      result: result,
    );
  }
}

// ignore: unused_element
const $GraphqlLoadedState = _$GraphqlLoadedStateTearOff();

mixin _$GraphqlLoadedState<T> {
  T get data;
  QueryResult get result;

  $GraphqlLoadedStateCopyWith<T, GraphqlLoadedState<T>> get copyWith;
}

abstract class $GraphqlLoadedStateCopyWith<T, $Res> {
  factory $GraphqlLoadedStateCopyWith(GraphqlLoadedState<T> value,
          $Res Function(GraphqlLoadedState<T>) then) =
      _$GraphqlLoadedStateCopyWithImpl<T, $Res>;
  $Res call({T data, QueryResult result});
}

class _$GraphqlLoadedStateCopyWithImpl<T, $Res>
    implements $GraphqlLoadedStateCopyWith<T, $Res> {
  _$GraphqlLoadedStateCopyWithImpl(this._value, this._then);

  final GraphqlLoadedState<T> _value;
  // ignore: unused_field
  final $Res Function(GraphqlLoadedState<T>) _then;

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

abstract class _$GraphqlLoadedStateCopyWith<T, $Res>
    implements $GraphqlLoadedStateCopyWith<T, $Res> {
  factory _$GraphqlLoadedStateCopyWith(_GraphqlLoadedState<T> value,
          $Res Function(_GraphqlLoadedState<T>) then) =
      __$GraphqlLoadedStateCopyWithImpl<T, $Res>;
  @override
  $Res call({T data, QueryResult result});
}

class __$GraphqlLoadedStateCopyWithImpl<T, $Res>
    extends _$GraphqlLoadedStateCopyWithImpl<T, $Res>
    implements _$GraphqlLoadedStateCopyWith<T, $Res> {
  __$GraphqlLoadedStateCopyWithImpl(_GraphqlLoadedState<T> _value,
      $Res Function(_GraphqlLoadedState<T>) _then)
      : super(_value, (v) => _then(v as _GraphqlLoadedState<T>));

  @override
  _GraphqlLoadedState<T> get _value => super._value as _GraphqlLoadedState<T>;

  @override
  $Res call({
    Object data = freezed,
    Object result = freezed,
  }) {
    return _then(_GraphqlLoadedState<T>(
      data: data == freezed ? _value.data : data as T,
      result: result == freezed ? _value.result : result as QueryResult,
    ));
  }
}

class _$_GraphqlLoadedState<T> extends _GraphqlLoadedState<T> {
  _$_GraphqlLoadedState({@required this.data, @required this.result})
      : assert(data != null),
        assert(result != null),
        super._();

  @override
  final T data;
  @override
  final QueryResult result;

  @override
  String toString() {
    return 'GraphqlLoadedState<$T>(data: $data, result: $result)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _GraphqlLoadedState<T> &&
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
  _$GraphqlLoadedStateCopyWith<T, _GraphqlLoadedState<T>> get copyWith =>
      __$GraphqlLoadedStateCopyWithImpl<T, _GraphqlLoadedState<T>>(
          this, _$identity);
}

abstract class _GraphqlLoadedState<T> extends GraphqlLoadedState<T> {
  _GraphqlLoadedState._() : super._();
  factory _GraphqlLoadedState(
      {@required T data,
      @required QueryResult result}) = _$_GraphqlLoadedState<T>;

  @override
  T get data;
  @override
  QueryResult get result;
  @override
  _$GraphqlLoadedStateCopyWith<T, _GraphqlLoadedState<T>> get copyWith;
}

class _$GraphqlRefetchStateTearOff {
  const _$GraphqlRefetchStateTearOff();

// ignore: unused_element
  _GraphqlRefetchState<T> call<T>({@required T data, QueryResult result}) {
    return _GraphqlRefetchState<T>(
      data: data,
      result: result,
    );
  }
}

// ignore: unused_element
const $GraphqlRefetchState = _$GraphqlRefetchStateTearOff();

mixin _$GraphqlRefetchState<T> {
  T get data;
  QueryResult get result;

  $GraphqlRefetchStateCopyWith<T, GraphqlRefetchState<T>> get copyWith;
}

abstract class $GraphqlRefetchStateCopyWith<T, $Res> {
  factory $GraphqlRefetchStateCopyWith(GraphqlRefetchState<T> value,
          $Res Function(GraphqlRefetchState<T>) then) =
      _$GraphqlRefetchStateCopyWithImpl<T, $Res>;
  $Res call({T data, QueryResult result});
}

class _$GraphqlRefetchStateCopyWithImpl<T, $Res>
    implements $GraphqlRefetchStateCopyWith<T, $Res> {
  _$GraphqlRefetchStateCopyWithImpl(this._value, this._then);

  final GraphqlRefetchState<T> _value;
  // ignore: unused_field
  final $Res Function(GraphqlRefetchState<T>) _then;

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

abstract class _$GraphqlRefetchStateCopyWith<T, $Res>
    implements $GraphqlRefetchStateCopyWith<T, $Res> {
  factory _$GraphqlRefetchStateCopyWith(_GraphqlRefetchState<T> value,
          $Res Function(_GraphqlRefetchState<T>) then) =
      __$GraphqlRefetchStateCopyWithImpl<T, $Res>;
  @override
  $Res call({T data, QueryResult result});
}

class __$GraphqlRefetchStateCopyWithImpl<T, $Res>
    extends _$GraphqlRefetchStateCopyWithImpl<T, $Res>
    implements _$GraphqlRefetchStateCopyWith<T, $Res> {
  __$GraphqlRefetchStateCopyWithImpl(_GraphqlRefetchState<T> _value,
      $Res Function(_GraphqlRefetchState<T>) _then)
      : super(_value, (v) => _then(v as _GraphqlRefetchState<T>));

  @override
  _GraphqlRefetchState<T> get _value => super._value as _GraphqlRefetchState<T>;

  @override
  $Res call({
    Object data = freezed,
    Object result = freezed,
  }) {
    return _then(_GraphqlRefetchState<T>(
      data: data == freezed ? _value.data : data as T,
      result: result == freezed ? _value.result : result as QueryResult,
    ));
  }
}

class _$_GraphqlRefetchState<T> extends _GraphqlRefetchState<T> {
  _$_GraphqlRefetchState({@required this.data, this.result})
      : assert(data != null),
        super._();

  @override
  final T data;
  @override
  final QueryResult result;

  @override
  String toString() {
    return 'GraphqlRefetchState<$T>(data: $data, result: $result)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _GraphqlRefetchState<T> &&
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
  _$GraphqlRefetchStateCopyWith<T, _GraphqlRefetchState<T>> get copyWith =>
      __$GraphqlRefetchStateCopyWithImpl<T, _GraphqlRefetchState<T>>(
          this, _$identity);
}

abstract class _GraphqlRefetchState<T> extends GraphqlRefetchState<T> {
  _GraphqlRefetchState._() : super._();
  factory _GraphqlRefetchState({@required T data, QueryResult result}) =
      _$_GraphqlRefetchState<T>;

  @override
  T get data;
  @override
  QueryResult get result;
  @override
  _$GraphqlRefetchStateCopyWith<T, _GraphqlRefetchState<T>> get copyWith;
}

class _$GraphqlFetchMoreStateTearOff {
  const _$GraphqlFetchMoreStateTearOff();

// ignore: unused_element
  _GraphqlFetchMoreState<T> call<T>({@required T data, QueryResult result}) {
    return _GraphqlFetchMoreState<T>(
      data: data,
      result: result,
    );
  }
}

// ignore: unused_element
const $GraphqlFetchMoreState = _$GraphqlFetchMoreStateTearOff();

mixin _$GraphqlFetchMoreState<T> {
  T get data;
  QueryResult get result;

  $GraphqlFetchMoreStateCopyWith<T, GraphqlFetchMoreState<T>> get copyWith;
}

abstract class $GraphqlFetchMoreStateCopyWith<T, $Res> {
  factory $GraphqlFetchMoreStateCopyWith(GraphqlFetchMoreState<T> value,
          $Res Function(GraphqlFetchMoreState<T>) then) =
      _$GraphqlFetchMoreStateCopyWithImpl<T, $Res>;
  $Res call({T data, QueryResult result});
}

class _$GraphqlFetchMoreStateCopyWithImpl<T, $Res>
    implements $GraphqlFetchMoreStateCopyWith<T, $Res> {
  _$GraphqlFetchMoreStateCopyWithImpl(this._value, this._then);

  final GraphqlFetchMoreState<T> _value;
  // ignore: unused_field
  final $Res Function(GraphqlFetchMoreState<T>) _then;

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

abstract class _$GraphqlFetchMoreStateCopyWith<T, $Res>
    implements $GraphqlFetchMoreStateCopyWith<T, $Res> {
  factory _$GraphqlFetchMoreStateCopyWith(_GraphqlFetchMoreState<T> value,
          $Res Function(_GraphqlFetchMoreState<T>) then) =
      __$GraphqlFetchMoreStateCopyWithImpl<T, $Res>;
  @override
  $Res call({T data, QueryResult result});
}

class __$GraphqlFetchMoreStateCopyWithImpl<T, $Res>
    extends _$GraphqlFetchMoreStateCopyWithImpl<T, $Res>
    implements _$GraphqlFetchMoreStateCopyWith<T, $Res> {
  __$GraphqlFetchMoreStateCopyWithImpl(_GraphqlFetchMoreState<T> _value,
      $Res Function(_GraphqlFetchMoreState<T>) _then)
      : super(_value, (v) => _then(v as _GraphqlFetchMoreState<T>));

  @override
  _GraphqlFetchMoreState<T> get _value =>
      super._value as _GraphqlFetchMoreState<T>;

  @override
  $Res call({
    Object data = freezed,
    Object result = freezed,
  }) {
    return _then(_GraphqlFetchMoreState<T>(
      data: data == freezed ? _value.data : data as T,
      result: result == freezed ? _value.result : result as QueryResult,
    ));
  }
}

class _$_GraphqlFetchMoreState<T> extends _GraphqlFetchMoreState<T> {
  _$_GraphqlFetchMoreState({@required this.data, this.result})
      : assert(data != null),
        super._();

  @override
  final T data;
  @override
  final QueryResult result;

  @override
  String toString() {
    return 'GraphqlFetchMoreState<$T>(data: $data, result: $result)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _GraphqlFetchMoreState<T> &&
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
  _$GraphqlFetchMoreStateCopyWith<T, _GraphqlFetchMoreState<T>> get copyWith =>
      __$GraphqlFetchMoreStateCopyWithImpl<T, _GraphqlFetchMoreState<T>>(
          this, _$identity);
}

abstract class _GraphqlFetchMoreState<T> extends GraphqlFetchMoreState<T> {
  _GraphqlFetchMoreState._() : super._();
  factory _GraphqlFetchMoreState({@required T data, QueryResult result}) =
      _$_GraphqlFetchMoreState<T>;

  @override
  T get data;
  @override
  QueryResult get result;
  @override
  _$GraphqlFetchMoreStateCopyWith<T, _GraphqlFetchMoreState<T>> get copyWith;
}
