import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../graphql_operation/queries/readRepositories.dart' as queries;

// to run the example, replace <YOUR_PERSONAL_ACCESS_TOKEN> with your GitHub token in ../local.dart
import '../local.dart';

class FetchMoreWidgetScreen extends StatelessWidget {
  const FetchMoreWidgetScreen() : super();

  @override
  Widget build(BuildContext context) {
    final httpLink =
        HttpLink('https://api.github.com/graphql', defaultHeaders: {
      'Authorization': 'Bearer $YOUR_PERSONAL_ACCESS_TOKEN',
    });

    final client = ValueNotifier<GraphQLClient>(
      GraphQLClient(
        cache: GraphQLCache(),
        link: httpLink,
      ),
    );

    return GraphQLProvider(
      client: client,
      child: const CacheProvider(
        child: MyHomePage(title: 'GraphQL Pagination'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
    this.title,
  }) : super(key: key);

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _searchQuery = 'flutter';
  int nRepositories = 10;

  void changeQuery(String query) {
    setState(() {
      print(query);
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search Query',
              ),
              keyboardType: TextInputType.text,
              onSubmitted: changeQuery,
            ),
            Query(
              options: QueryOptions(
                document: gql(queries.searchRepositories),
                variables: <String, dynamic>{
                  'nRepositories': nRepositories,
                  'query': _searchQuery,
                  // set cursor to null so as to start at the beginning
                  'cursor': null
                },
                //pollInterval: 10,
              ),
              builder: (QueryResult result, {refetch, FetchMore? fetchMore}) {
                if (result.hasException) {
                  return Text(result.exception.toString());
                }

                if (result.isLoading && result.data == null) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (result.data == null && !result.hasException) {
                  return const Text(
                      'Both data and errors are null, this is a known bug after refactoring, you might have forgotten to set Github token');
                }

                // result.data can be either a [List<dynamic>] or a [Map<String, dynamic>]
                final repositories =
                    (result.data!['search']['nodes'] as List<dynamic>);

                final Map pageInfo = result.data!['search']['pageInfo'];
                final String? fetchMoreCursor = pageInfo['endCursor'];
                final opts = FetchMoreOptions(
                  variables: {'cursor': fetchMoreCursor},
                  updateQuery: (previousResultData, fetchMoreResultData) {
                    // this is where you combine your previous data and response
                    // in this case, we want to display previous repos plus next repos
                    // so, we combine data in both into a single list of repos
                    final repos = [
                      ...previousResultData!['search']['nodes']
                          as List<dynamic>,
                      ...fetchMoreResultData!['search']['nodes']
                          as List<dynamic>
                    ];

                    // to avoid alot of work, lets just update the list of repos in returned
                    // data with new data, this also ensure we have the endCursor already set
                    // correctlty
                    fetchMoreResultData['search']['nodes'] = repos;

                    return fetchMoreResultData;
                  },
                );

                return Expanded(
                  child: ListView(
                    children: <Widget>[
                      for (var repository in repositories)
                        ListTile(
                          leading: (repository['viewerHasStarred'] as bool)
                              ? const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                )
                              : const Icon(Icons.star_border),
                          title: Text(repository['name'] as String),
                        ),
                      if (result.isLoading)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            CircularProgressIndicator(),
                          ],
                        ),
                      Text('note: this example has no mutations',
                          style: Theme.of(context).textTheme.caption),
                      ElevatedButton(
                        onPressed: () {
                          fetchMore!(opts);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text('Load More'),
                          ],
                        ),
                      )
                    ],
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
