import 'package:flutter/material.dart';
import './graphql_bloc/main.dart' show GraphQLBlocPatternScreen;

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
                        child: const Text('GraphQL BloC pattern'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<GraphQLBlocPatternScreen>(
                              builder: (BuildContext context) =>
                                  GraphQLBlocPatternScreen(),
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
