/// Deeply merges nested properties, returning a new [Map].
///
/// Properties of [other] will overwrite properties of [object].
Map<String, dynamic> deepMerge(
  Map<String, dynamic> object,
  Map<String, dynamic> other,
) {
  return {
    ...object,
    ...Map.fromEntries(other.entries.map((e) {
      final key = e.key;
      final objectValue = object[key];
      final otherValue = e.value;
      if (objectValue is Map<String, dynamic> &&
          otherValue is Map<String, dynamic>) {
        return MapEntry(
          key,
          deepMerge(
            objectValue,
            otherValue,
          ),
        );
      }
      return MapEntry(key, otherValue);
    }))
  };
}
