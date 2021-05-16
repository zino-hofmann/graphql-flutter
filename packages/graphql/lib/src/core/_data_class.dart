import 'package:meta/meta.dart';
import "package:collection/collection.dart";

/// Helper for making mutable data classes with
/// a [properties] based [equal] helper
///
/// NOTE: I (@micimize) settled on this helper instead of truly immutable classes
/// because I didn't want to deal with the issue of `copyWith(field: null)`,
/// but also didn't want to commit to adding a true dataclass generator
/// like `freezed` or `built_value` yet. I consider this a stopgap,
/// and think we should eventually have a truly immutable API
abstract class MutableDataClass {
  const MutableDataClass();

  /// identifying properties for the inheriting class
  @protected
  List<Object?> get properties;

  /// [properties] based deep equality check
  bool equal(MutableDataClass other) =>
      identical(this, other) ||
      (runtimeType == other.runtimeType &&
          const ListEquality<Object?>(
            DeepCollectionEquality(),
          ).equals(
            other.properties,
            properties,
          ));
}
