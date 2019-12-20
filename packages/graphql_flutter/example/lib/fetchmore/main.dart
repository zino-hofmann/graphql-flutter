import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../graphql_operation/queries/readRepositories.dart' as queries;

// ignore: uri_does_not_exist
import '../local.dart';

class FetchMoreWidgetScreen extends StatelessWidget {
  const FetchMoreWidgetScreen() : super();

  @override
  Widget build(BuildContext context) {
    final HttpLink httpLink = HttpLink(
      uri: 'https://api.github.com/graphql',
    );

    final AuthLink authLink = AuthLink(
      // ignore: undefined_identifier
      getToken: () async => 'Bearer $YOUR_PERSONAL_ACCESS_TOKEN',
    );

    Link link = authLink.concat(httpLink);

    final ValueNotifier<GraphQLClient> client = ValueNotifier<GraphQLClient>(
      GraphQLClient(
        cache: InMemoryCache(),
        link: link,
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
    Key key,
    this.title,
  }) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _searchQuery = "flutter";
  int nRepositories = 10;

  void changeQuery(String query) {
    setState(() {
      print(query);
      _searchQuery = query ?? "flutter";
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
                labelText: 'Search Query',
              ),
              keyboardType: TextInputType.text,
              onSubmitted: changeQuery,
            ),
            Query(
              options: QueryOptions(
                documentNode: gql(queries.searchRepositories),
                variables: <String, dynamic>{
                  'nRepositories': nRepositories,
                  'query': _searchQuery,
                  // set cursor to null so as to start at the beginning
                  'cursor': null
                },
                //pollInterval: 10,
              ),
              builder: (QueryResult result, {refetch, FetchMore fetchMore}) {
                if (result.hasException) {
                  return Text(result.exception.toString());
                }

                if (result.loading && result.data == null) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (result.data == null && !result.hasException) {
                  return const Text(
                      'Both data and errors are null, this is a known bug after refactoring, you might have forgotten to set Github token');
                }

                // result.data can be either a [List<dynamic>] or a [Map<String, dynamic>]
                final List<dynamic> repositories =
                    (result.data['search']['nodes'] as List<dynamic>);

                final Map pageInfo = result.data['search']['pageInfo'];
                final String fetchMoreCursor = pageInfo['endCursor'];
                FetchMoreOptions opts = FetchMoreOptions(
                  variables: {'cursor': fetchMoreCursor},
                  updateQuery: (previousResultData, fetchMoreResultData) {
                    // this is where you combine your previous data and response
                    // in this case, we want to display previous repos plus next repos
                    // so, we combine data in both into a single list of repos
                    final List<dynamic> repos = [
                      ...previousResultData['search']['nodes'] as List<dynamic>,
                      ...fetchMoreResultData['search']['nodes'] as List<dynamic>
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
                      if (result.loading)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            CircularProgressIndicator(),
                          ],
                        ),
                      RaisedButton(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text("Load More"),
                          ],
                        ),
                        onPressed: () {
                          fetchMore(opts);
                        },
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
