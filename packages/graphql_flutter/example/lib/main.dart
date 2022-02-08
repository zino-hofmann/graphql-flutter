import 'package:flutter/material.dart';
import 'package:trash_themes/themes.dart';
import './graphql_bloc/main.dart' show GraphQLBlocPatternScreen;
import './graphql_widget/main.dart' show GraphQLWidgetScreen;
import 'fetchmore/main.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GraphQL Flutter Demo',
      theme: DraculaTheme().makeDarkTheme(context: context),
      home: Builder(
        builder: (BuildContext context) => Scaffold(
          appBar: AppBar(
            title: const Text('GraphQL Demo App'),
          ),
          body: Center(
            child: Column(
              children: <Widget>[
                Spacer(),
                Flexible(
                    child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<GraphQLWidgetScreen>(
                        builder: (BuildContext context) =>
                            GraphQLBlocPatternScreen(),
                      ),
                    );
                  },
                  child: const Text('GraphQL BloC pattern'),
                )),
                Spacer(),
                Flexible(
                    child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<GraphQLWidgetScreen>(
                        builder: (BuildContext context) =>
                            const GraphQLWidgetScreen(),
                      ),
                    );
                  },
                  child: const Text('GraphQL Widget'),
                )),
                Spacer(),
                Flexible(
                    child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<FetchMoreWidgetScreen>(
                        builder: (BuildContext context) =>
                            const FetchMoreWidgetScreen(),
                      ),
                    );
                  },
                  child: const Text('Fetchmore (Pagination) Example'),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
