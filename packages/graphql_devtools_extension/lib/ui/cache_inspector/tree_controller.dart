import 'package:flutter/material.dart';

/// A controller for a tree state.
///
/// Allows to modify the state of the tree.
class TreeController {
  TreeController({bool allNodesExpanded = true})
      : _allNodesExpanded = allNodesExpanded;
  bool _allNodesExpanded;
  final Map<Key, bool> _expanded = <Key, bool>{};

  bool get allNodesExpanded => _allNodesExpanded;

  bool isNodeExpanded(Key key) {
    return _expanded[key] ?? _allNodesExpanded;
  }

  void toggleNodeExpanded(Key key) {
    _expanded[key] = !isNodeExpanded(key);
  }

  void expandAll() {
    _allNodesExpanded = true;
    _expanded.clear();
  }

  void collapseAll() {
    _allNodesExpanded = false;
    _expanded.clear();
  }

  void expandNode(Key key) {
    _expanded[key] = true;
  }

  void collapseNode(Key key) {
    _expanded[key] = false;
  }
}
