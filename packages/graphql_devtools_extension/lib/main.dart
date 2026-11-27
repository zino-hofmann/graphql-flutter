import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'package:graphql_devtools_extension/ui/cache_inspector/cache_inspector.dart';

void main() {
  runApp(DevToolsExtension(child: GraphQLDevToolsExtension()));
}

class GraphQLDevToolsExtension extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 1,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TabBar(
              isScrollable: true,
              tabs: [
                Tab(
                  child: Text(
                    'Cache Inspector',
                    style: theme.textTheme.titleMedium,
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: TabBarView(children: [const CacheInspector()]),
          ),
        ],
      ),
    );
  }
}
