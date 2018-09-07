import 'package:flutter/material.dart';

import 'package:graphql_flutter/graphql_flutter.dart';

import './mutations/addStar.dart' as mutations;
import './queries/readRepositories.dart' as queries;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    HttpLink link = HttpLink(
      uri: 'https://api.github.com/graphql',
      headers: <String, String>{
        'Authorization': 'Bearer <YOUR_PERSONAL_ACCESS_TOKEN>',
      },
    );

    ValueNotifier<GraphQLClient> client = ValueNotifier(
      GraphQLClient(
        cache: InMemoryCache(),
        link: link,
      ),
    );

    return GraphQLProvider(
      client: client,
      child: CacheProvider(
        child: MaterialApp(
          title: 'GraphQL Flutter Demo',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: MyHomePage(title: 'GraphQL Flutter Home Page'),
        ),
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
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Query(
        options: QueryOptions(
          document: queries.readRepositories,
          pollInterval: 4,
          // you can optionally override some http options through the contexts
          context: <String, dynamic>{
            'headers': <String, String>{
              'Authorization': 'Bearer <YOUR_PERSONAL_ACCESS_TOKEN>',
            },
          },
        ),
        builder: (QueryResult result) {
          if (result.errors != null) {
            return Text(result.errors.toString());
          }

          if (result.loading) {
            return Text('Loading');
          }

          // result.data can be either a Map or a List
          List repositories = result.data['viewer']['repositories']['nodes'];

          return ListView.builder(
            itemCount: repositories.length,
            itemBuilder: (context, index) {
              final Map<String, dynamic> repository = repositories[index];

              return Mutation(
                options: MutationOptions(
                  document: mutations.addStar,
                ),
                builder: (
                  RunMutation addStar,
                  QueryResult addStarResult,
                ) {
                  if (addStarResult.data != null &&
                      (addStarResult.data as Map).isNotEmpty) {
                    repository['viewerHasStarred'] = addStarResult
                        .data['addStar']['starrable']['viewerHasStarred'];
                  }

                  return ListTile(
                    leading: (repository['viewerHasStarred'] as bool)
                        ? const Icon(Icons.star, color: Colors.amber)
                        : const Icon(Icons.star_border),
                    title: Text(repository['name'] as String),
                    // optimistic ui updates are not implemented yet, therefore changes may take some time to show
                    onTap: () {
                      addStar(<String, dynamic>{
                        'starrableId': repository['id'],
                      });
                    },
                  );
                },
                onCompleted: (QueryResult onCompleteResult) {
                  showDialog<AlertDialog>(
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
