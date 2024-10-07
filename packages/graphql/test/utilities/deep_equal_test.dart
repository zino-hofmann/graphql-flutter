// FROM https://github.com/dart-lang/collection/blob/2d57a82ad079fe2d127f5a9b188170de2f5cdedc/test/equality_test.dart#L143

import 'package:graphql/src/utilities/deep_equal.dart';
import 'package:test/test.dart';

void main() {
  Element o(int id) => Element(id);

  // // Lists that are point-wise equal, but not identical.
  // var list1 = [o(1), o(2), o(3), o(4), o(5)];
  // var list2 = [o(1), o(2), o(3), o(4), o(5)];
  // // Similar length list with equal elements in different order.
  // var list3 = [o(1), o(3), o(5), o(4), o(2)];

  var map1a = {
    'x': [o(1), o(2), o(3)],
    'y': [true, false, null]
  };
  var map1b = {
    'x': [o(4), o(5), o(6)],
    'y': [false, true, null]
  };
  var map2a = {
    'x': [o(3), o(2), o(1)],
    'y': [false, true, null]
  };
  var map2b = {
    'x': [o(6), o(5), o(4)],
    'y': [null, false, true]
  };
  var l1 = [map1a, map1b];
  var l2 = [map2a, map2b];
  var s1 = {...l1};
  var s2 = {map2b, map2a};

  var i1 = Iterable.generate(l1.length, (i) => l1[i]);

  group('DeepEquality', () {
    group('ordered', () {
      test('with identical collection types', () {
        expect(jsonMapEquals(l1, l1.toList()), isTrue);
        expect(jsonMapEquals(s1, s1.toSet()), isTrue);
        expect(jsonMapEquals(map1b, map1b.map(MapEntry.new)), isTrue);
        expect(jsonMapEquals(i1, i1.map((i) => i)), isTrue);
        expect(jsonMapEquals(map1a, map2a), isFalse);
        expect(jsonMapEquals(map1b, map2b), isFalse);
        expect(jsonMapEquals(l1, l2), isFalse);
        expect(jsonMapEquals(s1, s2), isFalse);
      });
    });
  });
}

/// Wrapper objects for an `id` value.
///
/// Compares the `id` value by equality and for comparison.
/// Allows creating simple objects that are equal without being identical.
class Element implements Comparable<Element> {
  final int id;
  const Element(this.id);
  @override
  int get hashCode => id.hashCode;
  @override
  bool operator ==(Object other) => other is Element && id == other.id;
  @override
  int compareTo(Element other) => id.compareTo(other.id);

  @override
  String toString() {
    return 'Element($id)';
  }
}
