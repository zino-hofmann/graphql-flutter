bool jsonMapEquals(dynamic a, dynamic b) {
  if (identical(a, b)) {
    return true;
  }
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (var key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (!jsonMapEquals(a[key], b[key])) return false;
    }
    return true;
  }
  if (a is Iterable && b is Iterable) {
    final length = a.length;
    if (length != b.length) return false;
    for (var i = 0; i < length; i++) {
      if (!jsonMapEquals(a.elementAt(i), b.elementAt(i))) return false;
    }
    return true;
  }

  return a == b;
}
