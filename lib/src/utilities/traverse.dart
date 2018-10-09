typedef Object Transform(Object node);

Map<String, Object> traverseValues(
  Map<String, Object> node,
  Transform transform,
) {
  return node.map<String, Object>(
    (String key, Object value) => MapEntry<String, Object>(
          key,
          traverse(value, transform),
        ),
  );
}

// Attempts to apply the transform to every leaf of the data structure recursively.
// Stops recursing when a node is transformed (returns non-null)
Object traverse(Object node, Transform transform) {
  final Object transformed = transform(node);
  if (transformed != null) {
    return transformed;
  }

  if (node is List<Object>) {
    return node
        .map<Object>((Object node) => traverse(node, transform))
        .toList();
  }
  if (node is Map<String, Object>) {
    return traverseValues(node, transform);
  }
  return node;
}
