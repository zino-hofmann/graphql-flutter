import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import './queries/readRepositories.dart' as queries;
import './mutations/addStar.dart' as mutations;

void main() {
  client = new Client(
    endPoint: 'https://api.github.com/graphql',
    cache: new InMemoryCache(),
  );
  client.apiToken = '<YOUR_GITHUB_PERSONAL_ACCESS_TOKEN>';

  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new CacheProvider(
      child: new MaterialApp(
        title: 'Flutter Demo',
        theme: new ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: new MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({
    Key key,
    this.title,
  }) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new Query(
        queries.readRepositories,
        pollInterval: 1,
        builder: ({
          bool loading,
          Map data,
          String error,
        }) {
          if (error != '') {
            return new Text(error);
          }

          if (loading) {
            return new Text('Loading');
          }

          // it can be either Map or List
          List repositories = data['viewer']['repositories']['nodes'];

          return new ListView.builder(
            itemCount: repositories.length,
            itemBuilder: (context, index) {
              final repository = repositories[index];

              return new Mutation(
                mutations.addStar,
                onCompleted: (Map<String, dynamic> data) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Thanks for your star!'),
                        actions: <Widget>[
                          SimpleDialogOption(
                            child: Text('Dismiss'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          )
                        ],
                      );
                    }
                  );
                },
                builder: (
                  addStar, {
                  bool loading,
                  Map data,
                  String error,
                }) {
                  return new ListTile(
                    leading: repository['viewerHasStarred']
                        ? const Icon(Icons.star, color: Colors.amber)
                        : const Icon(Icons.star_border),
                    title: new Text(repository['name']),
                    // NOTE: optimistic ui updates are not implemented yet, therefore changes may take upto 1 second to show.
                    onTap: () {
                      addStar({
                        'starrableId': repository['id'],
                      });
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
