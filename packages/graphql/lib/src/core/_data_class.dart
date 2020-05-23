import 'package:meta/meta.dart';
import "package:collection/collection.dart";

/// Helper for making mutable data clases
abstract class MutableDataClass {
  const MutableDataClass();

  /// identifying properties for the inheriting class
  @protected
  List<Object> get properties;

  /// [properties] based equality check
  bool equal(MutableDataClass other) =>
      identical(this, other) ||
      (runtimeType == other.runtimeType &&
          const ListEquality<Object>(
            DeepCollectionEquality(),
          ).equals(
            other.properties,
            properties,
          ));
}
