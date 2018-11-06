import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

// create this file with the line
// const String YOUR_PERSONAL_ACCESS_TOKEN = '<YOUR_PERSONAL_ACCESS_TOKEN>';
import './local.dart';

import './queries/readRepositories.dart' as queries;
import './starrable_repository.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final HttpLink link = HttpLink(
      uri: 'https://api.github.com/graphql',
      headers: <String, String>{
        'Authorization': 'Bearer $YOUR_PERSONAL_ACCESS_TOKEN',
      },
    );

    final ValueNotifier<GraphQLClient> client = ValueNotifier<GraphQLClient>(
      GraphQLClient(
        cache: NormalizedInMemoryCache(
          dataIdFromObject: typenameDataIdFromObject,
        ),
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
          home: const MyHomePage(title: 'GraphQL Flutter Home Page'),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key key,
    this.title,
  }) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int nRepositories = 50;

  void changeQuery(String number) {
    setState(() {
      nRepositories = int.parse(number) ?? 50;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            TextField(
              decoration: const InputDecoration(
                labelText: 'Number of repositories (default 50)',
              ),
              keyboardType: TextInputType.number,
              onSubmitted: changeQuery,
            ),
            Query(
              options: QueryOptions(
                document: queries.readRepositories,
                variables: <String, dynamic>{
                  'nRepositories': nRepositories,
                },
                pollInterval: 4,
                // you can optionally override some http options through the contexts
                context: <String, dynamic>{
                  'headers': <String, String>{
                    'Authorization': 'Bearer $YOUR_PERSONAL_ACCESS_TOKEN',
                  },
                },
              ),
              builder: (QueryResult result) {
                if (result.loading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (result.hasErrors) {
                  return Text('\nErrors: \n  ' + result.errors.join(',\n  '));
                }

                // result.data can be either a [List<dynamic>] or a [Map<String, dynamic>]
                final List<dynamic> repositories =
                    result.data['viewer']['repositories']['nodes'];

                return Expanded(
                  child: ListView.builder(
                    itemCount: repositories.length,
                    itemBuilder: (BuildContext context, int index) =>
                        StarrableRepository(repository: repositories[index]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
