import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import './mutations/mutations.dart' as mutations;
import './queries/readRepositories.dart' as queries;

const String YOUR_PERSONAL_ACCESS_TOKEN = '<YOUR_PERSONAL_ACCESS_TOKEN>';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final HttpLink httpLink = HttpLink(
      uri: 'https://api.github.com/graphql',
    );

    final AuthLink authLink = AuthLink(
      getToken: () => 'Bearer $YOUR_PERSONAL_ACCESS_TOKEN',
    );

    final Link link = authLink.concat(httpLink);

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

class StarrableRepository extends StatefulWidget {
  const StarrableRepository({
    Key key,
    @required this.repository,
  }) : super(key: key);

  final Map<String, Object> repository;

  @override
  StarrableRepositoryState createState() {
    return new StarrableRepositoryState();
  }
}

class StarrableRepositoryState extends State<StarrableRepository> {
  bool loading = false;

  Map<String, Object> extractRepositoryData(Map<String, Object> data) {
    final Map<String, Object> action = data['action'];

    if (action == null) {
      return null;
    }

    return action['starrable'];
  }

  bool get viewerHasStarred => widget.repository['viewerHasStarred'];

  @override
  Widget build(BuildContext context) {
    final bool starred = loading ? !viewerHasStarred : viewerHasStarred;

    return Mutation(
      key: Key(starred.toString()),
      options: MutationOptions(
        document: starred ? mutations.removeStar : mutations.addStar,
      ),
      builder: (RunMutation toggleStar, QueryResult result) {
        return ListTile(
          leading: starred
              ? const Icon(
                  Icons.star,
                  color: Colors.amber,
                )
              : const Icon(Icons.star_border),
          trailing: loading ? const CircularProgressIndicator() : null,
          title: Text(widget.repository['name']),
          onTap: () {
            // optimistic ui updates are not implemented yet,
            // so we track loading manually
            setState(() {
              loading = true;
            });
            toggleStar(<String, dynamic>{
              'starrableId': widget.repository['id'],
            });
          },
        );
      },
      update: (Cache cache, QueryResult result) {
        if (result.hasErrors) {
          print(result.errors);
        } else {
          final Map<String, Object> updated =
              Map<String, Object>.from(widget.repository)
                ..addAll(extractRepositoryData(result.data));

          cache.write(typenameDataIdFromObject(updated), updated);
        }
      },
      onCompleted: (QueryResult result) {
        showDialog<AlertDialog>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                extractRepositoryData(result.data)['viewerHasStarred']
                    ? 'Thanks for your star!'
                    : 'Sorry you changed your mind!',
              ),
              actions: <Widget>[
                SimpleDialogOption(
                  child: const Text('Dismiss'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          },
        );
        setState(() {
          loading = false;
        });
      },
    );
  }
}
