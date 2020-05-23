import 'package:meta/meta.dart';
import "package:collection/collection.dart";

/// Similar to Equatable using the same approach as `gql`'s data classes
@immutable
abstract class DataClass {
  const DataClass();

  @protected
  List<Object> get properties;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DataClass &&
          runtimeType == other.runtimeType &&
          const ListEquality<Object>(
            DeepCollectionEquality(),
          ).equals(
            other.properties,
            properties,
          ));

  @override
  int get hashCode => const ListEquality<Object>(
        DeepCollectionEquality(),
      ).hash(properties);
}
