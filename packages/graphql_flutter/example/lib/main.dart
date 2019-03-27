import 'package:flutter/material.dart';
import './graphql_widget/main.dart' show GraphQLWidgetScreen;

void main() => runApp(
      MaterialApp(
        title: 'GraphQL Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Builder(
          builder: (BuildContext context) => Scaffold(
                appBar: AppBar(
                  title: const Text('GraphQL Demo App'),
                ),
                body: Center(
                  child: Column(
                    children: <Widget>[
                      RaisedButton(
                        child: const Text('GraphQL Widget'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<GraphQLWidgetScreen>(
                              builder: (BuildContext context) =>
                                  const GraphQLWidgetScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
        ),
      ),
    );
