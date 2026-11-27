import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/material.dart';
import 'package:graphql_devtools_extension/api/app_connection.dart';
import 'package:graphql_devtools_extension/ui/cache_inspector/tree_controller.dart';
import 'package:graphql_devtools_extension/ui/cache_inspector/tree_view.dart';

class SelectedCache {
  const SelectedCache({required this.key, required this.value});
  final String key;
  final dynamic value;
}

class CacheInspector extends StatefulWidget {
  const CacheInspector({Key? key}) : super(key: key);
  @override
  _CacheInspectorState createState() => _CacheInspectorState();
}

class _CacheInspectorState extends State<CacheInspector> {
  static const _queryKey = 'Query';
  static const _mutationKey = 'Mutation';

  Map<String, dynamic>? sourceData;
  Map<String, dynamic>? cache;
  Map<String, dynamic>? query;
  Map<String, dynamic>? mutation;
  String q = '';
  SelectedCache? selectedCache;
  bool showSearchTab = false;
  late TreeController treeController;
  late Future<Map<String, dynamic>?> response;

  @override
  void initState() {
    super.initState();
    treeController = TreeController();
    response = AppConnection.fetchCache();
    response.then((cacheMap) {
      if (cacheMap != null) {
        setState(() {
          sourceData = Map<String, dynamic>.from(cacheMap);
          query = _sortCache(cacheMap[_queryKey] as Map<String, dynamic>?);
          mutation =
              _sortCache(cacheMap[_mutationKey] as Map<String, dynamic>?);
          cache = _sortCache(cacheMap
            ..remove(_queryKey)
            ..remove(_mutationKey));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 3,
      child: Split(
        initialFractions: const [0.5, 0.5],
        axis: Axis.horizontal,
        children: [
          RoundedOutlinedBorder(
            clip: true,
            child: Column(
              children: [
                Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TabBar(
                        isScrollable: true,
                        tabs: [
                          Tab(
                            child: Text(
                              'Cache',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          Tab(
                            child: Text(
                              _queryKey,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          Tab(
                            child: Text(
                              _mutationKey,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 48,
                      child: InkWell(
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.search),
                        ),
                        onTap: () {
                          setState(() {
                            showSearchTab = !showSearchTab;
                          });
                        },
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 0,
                      child: InkWell(
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.refresh),
                        ),
                        onTap: () async {
                          q = '';
                          selectedCache = null;
                          showSearchTab = false;
                          final cacheMap = await AppConnection.fetchCache();
                          if (cacheMap is Map<String, dynamic>) {
                            setState(() {
                              sourceData = cacheMap;
                              query =
                                  cacheMap[_queryKey] is Map<String, dynamic>
                                      ? _sortCache(cacheMap[_queryKey]
                                          as Map<String, dynamic>)
                                      : {};
                              mutation =
                                  cacheMap[_mutationKey] is Map<String, dynamic>
                                      ? _sortCache(cacheMap[_mutationKey]
                                          as Map<String, dynamic>)
                                      : {};
                              final cacheMapCopy =
                                  Map<String, dynamic>.from(cacheMap);
                              cache = _sortCache(cacheMapCopy
                                ..remove(_queryKey)
                                ..remove(_mutationKey));
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const Divider(height: 1),
                if (showSearchTab) ...[
                  const SizedBox(height: 8),
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Search Cache',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                    onChanged: (value) {
                      if (sourceData == null) return;
                      final cacheCopy = Map<String, dynamic>.from(sourceData!);
                      final tmpQuery = cacheCopy[_queryKey];
                      final tmpMutation = cacheCopy[_mutationKey];
                      setState(() {
                        query = _sortCache(_filterCache(
                            tmpQuery as Map<String, dynamic>?, value));
                        mutation = _sortCache(_filterCache(
                            tmpMutation as Map<String, dynamic>?, value));
                        cache = _sortCache(_filterCache(
                          cacheCopy
                            ..remove(_queryKey)
                            ..remove(_mutationKey),
                          value,
                        ));
                        q = value;
                      });
                    },
                  ),
                ],
                Expanded(
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildTreeView(
                        context,
                        data: cache,
                        onTap: (key, value) {
                          if (key != null) {
                            setState(() {
                              selectedCache =
                                  SelectedCache(key: key, value: value);
                            });
                          }
                        },
                      ),
                      _buildTreeView(
                        context,
                        data: query,
                        onTap: (key, value) {
                          if (key != null) {
                            setState(() {
                              selectedCache =
                                  SelectedCache(key: key, value: value);
                            });
                          }
                        },
                      ),
                      _buildTreeView(
                        context,
                        data: mutation,
                        onTap: (key, value) {
                          if (key != null) {
                            setState(() {
                              selectedCache =
                                  SelectedCache(key: key, value: value);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          RoundedOutlinedBorder(
            clip: true,
            child: SafeArea(
              child: SingleChildScrollView(
                child: TreeView(
                  treeController: treeController,
                  nodes: selectedCache == null
                      ? [const TreeNode(children: [])]
                      : _convertToTreeNodes({
                          selectedCache!.key:
                              _sortCacheValue(selectedCache!.value)
                        }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeView(
    BuildContext context, {
    required Map<String, dynamic>? data,
    required void Function(String? key, dynamic value) onTap,
  }) {
    return ListView.builder(
      itemCount: data?.length ?? 0,
      itemBuilder: (context, index) {
        final key = data?.keys.elementAt(index);
        return ListTile(
          title: Text('$key: ', style: Theme.of(context).textTheme.titleMedium),
          onTap: () => onTap(key, data?[key]),
        );
      },
    );
  }

  List<TreeNode> _convertToTreeNodes(dynamic parsedJson) {
    if (parsedJson is Map<String, dynamic>) {
      return parsedJson.keys
          .map((k) => TreeNode(
              content: '$k:', children: _convertToTreeNodes(parsedJson[k])))
          .toList();
    }
    if (parsedJson is List<dynamic>) {
      if (parsedJson.isEmpty) return [const TreeNode(content: '[]')];
      return parsedJson
          .asMap()
          .map((i, element) => MapEntry(
              i,
              TreeNode(
                  content: '[$i]:', children: _convertToTreeNodes(element))))
          .values
          .toList();
    }
    return [TreeNode(content: parsedJson.toString())];
  }

  Map<String, dynamic> _sortCache(Map<String, dynamic>? cacheMap) {
    if (cacheMap == null) return {};
    final sortedKeys = cacheMap.keys.toList()..sort((a, b) => a.compareTo(b));
    return {for (var key in sortedKeys) key: cacheMap[key]};
  }

  dynamic _sortCacheValue(dynamic cacheValue) {
    if (cacheValue is! Map<String, dynamic>) return cacheValue;
    final sortedKeys = cacheValue.keys.toList()
      ..sort((a, b) {
        if (a == 'id') return -1;
        if (b == 'id') return 1;
        if (a == '__typename') return -1;
        if (b == '__typename') return 1;
        final isAMap = cacheValue[a] is Map || cacheValue[a] is List;
        final isBMap = cacheValue[b] is Map || cacheValue[b] is List;
        if (isAMap && !isBMap) return 1;
        if (!isAMap && isBMap) return -1;
        return a.compareTo(b);
      });
    return {for (var key in sortedKeys) key: cacheValue[key]};
  }

  Map<String, dynamic> _filterCache(Map<String, dynamic>? cacheMap, String q) {
    if (cacheMap == null) return {};
    if (q.isEmpty) return cacheMap;
    return cacheMap.map(
        (k, v) => k.contains(q) ? MapEntry(k, v) : const MapEntry('', null))
      ..removeWhere((key, value) => key.isEmpty);
  }
}
