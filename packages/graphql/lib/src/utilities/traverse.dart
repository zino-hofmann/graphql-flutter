import 'dart:collection';

typedef Transform = Object Function(Object node);
typedef SideEffect = void Function(
  Object transformResult,
  Object node,
  Traversal traversal,
);

class Traversal {
  Traversal(
    this.transform, {
    this.transformSideEffect,
    this.seenObjects,
  }) {
    seenObjects ??= HashSet<Object>();
  }

  Transform transform;

  /// An optional side effect to call when a node is transformed.
  SideEffect transformSideEffect;
  HashSet<Object> seenObjects;

  bool alreadySeen(Object node) {
    final bool wasAdded = seenObjects.add(node);
    return !wasAdded;
  }

  /// Traverse only the values of the given map
  Map<String, Object> traverseValues(Map<String, Object> node) {
    return node.map<String, Object>(
      (String key, Object value) => MapEntry<String, Object>(
        key,
        traverse(value),
      ),
    );
  }

  // Attempts to apply the transform to every leaf of the data structure recursively.
  // Stops recursing when a node is transformed (returns non-null)
  Object traverse(Object node) {
    final Object transformed = transform(node);
    if (alreadySeen(node)) {
      return transformed ?? node;
    }
    if (transformed != null) {
      if (transformSideEffect != null) {
        transformSideEffect(transformed, node, this);
      }
      return transformed;
    }

    if (node is List<Object>) {
      return node.map<Object>((Object node) => traverse(node)).toList();
    }
    if (node is Map<String, Object>) {
      return traverseValues(node);
    }
    return node;
  }
}
