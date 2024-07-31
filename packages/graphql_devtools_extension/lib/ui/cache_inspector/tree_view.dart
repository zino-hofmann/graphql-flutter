import 'package:flutter/material.dart';
import 'package:graphql_devtools_extension/ui/cache_inspector/tree_controller.dart';

/// Tree view with collapsible and expandable nodes.
class TreeView extends StatelessWidget {
  TreeView({
    required List<TreeNode> nodes,
    required this.treeController,
    this.indent = 32,
    this.iconSize,
  }) : nodes = _copyNodesRecursively(nodes, _KeyProvider())!;

  /// List of root level tree nodes.
  final List<TreeNode> nodes;

  /// Horizontal indent between levels.
  final double? indent;

  /// Size of the expand/collapse icon.
  final double? iconSize;

  /// Tree controller to manage the tree state.
  final TreeController treeController;

  @override
  Widget build(BuildContext context) {
    return _buildNodes(nodes, indent, treeController, iconSize);
  }
}

/// Widget that displays one [TreeNode] and its children.
class NodeWidget extends StatefulWidget {
  const NodeWidget({
    required this.treeNode,
    required this.treeController,
    this.indent,
    this.iconSize,
  });
  final TreeNode treeNode;
  final double? indent;
  final double? iconSize;
  final TreeController treeController;
  @override
  _NodeWidgetState createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> {
  late bool isExpanded;
  @override
  void initState() {
    super.initState();
    isExpanded = widget.treeController.isNodeExpanded(widget.treeNode.key!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLeaf = widget.treeNode.children?.length == 1 &&
        widget.treeNode.children!.first.children == null;
    if (isLeaf) {
      return ListTile(
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${widget.treeNode.content} ',
                style: theme.textTheme.titleMedium,
              ),
              TextSpan(
                text: widget.treeNode.children!.first.content,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () {
              setState(() {
                widget.treeController.toggleNodeExpanded(widget.treeNode.key!);
                isExpanded =
                    widget.treeController.isNodeExpanded(widget.treeNode.key!);
              });
            },
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: widget.iconSize,
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.treeNode.content,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: widget.indent! + 8.0),
                  child: _buildNodes(
                    widget.treeNode.children!,
                    widget.indent,
                    widget.treeController,
                    widget.iconSize,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _TreeNodeKey extends ValueKey<int> {
  const _TreeNodeKey(int value) : super(value);
}

/// Provides unique keys and verifies duplicates.
class _KeyProvider {
  int _nextIndex = 0;
  final Set<Key> _keys = <Key>{};

  /// If [originalKey] is null, generates new key, otherwise verifies the key
  /// was not met before.
  Key key(Key? originalKey) {
    if (originalKey == null) {
      return _TreeNodeKey(_nextIndex++);
    }
    if (_keys.contains(originalKey)) {
      throw ArgumentError('There should not be nodes with the same kays. '
          'Duplicate value found: $originalKey.');
    }
    _keys.add(originalKey);
    return originalKey;
  }
}

/// One node of a tree.
class TreeNode {
  const TreeNode({this.children, this.content = '', this.key});

  final List<TreeNode>? children;
  final String content;
  final Key? key;
}

/// Builds set of [nodes] respecting [state], [indent] and [iconSize].
Widget _buildNodes(
  Iterable<TreeNode> nodes,
  double? indent,
  TreeController state,
  double? iconSize,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final node in nodes)
        NodeWidget(
          treeNode: node,
          indent: indent,
          treeController: state,
          iconSize: iconSize,
        ),
    ],
  );
}

List<TreeNode>? _copyNodesRecursively(
  List<TreeNode>? nodes,
  _KeyProvider keyProvider,
) {
  if (nodes == null) {
    return null;
  }
  return List.unmodifiable(
    nodes.map(
      (n) {
        return TreeNode(
          key: keyProvider.key(n.key),
          content: n.content,
          children: _copyNodesRecursively(n.children, keyProvider),
        );
      },
    ),
  );
}
