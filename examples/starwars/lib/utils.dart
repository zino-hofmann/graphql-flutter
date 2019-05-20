import 'dart:async' show Future;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

RegExp importStatement = RegExp(r'^#import (\w+)\s*', multiLine: true);

// TODO this is pretty slipshod - inlines `#import $name` calls
// TODO dedupe names
Future<String> loadGQL(String name) async {
  String body = await rootBundle.loadString('lib/gql/$name.gql');
  for (Match dependency in importStatement.allMatches(body)) {
    String dep = await loadGQL(dependency.group(1));
    body = dep + '\n' + body;
  }
  return body;
}

typedef Widget GQLBuilder(BuildContext context, String gql, Object error);

class GQLProvider extends StatefulWidget {
  final String filename;
  final GQLBuilder builder;
  GQLProvider(this.filename, this.builder);

  _GQLProviderState createState() => _GQLProviderState();
}

class _GQLProviderState extends State<GQLProvider> {
  Future<String> gql;
  @override
  void initState() {
    gql = loadGQL(widget.filename);
    super.initState();
  }

  @override
  void didUpdateWidget(oldWidget) {
    if (widget.filename != oldWidget.filename) {
      gql = loadGQL(widget.filename);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: gql,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.active:
          case ConnectionState.waiting:
            return Container();
          case ConnectionState.done:
          default:
            return widget.builder(
              context,
              snapshot.data as String,
              snapshot.error,
            );
        }
      },
    );
  }
}
