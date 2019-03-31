import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../graphql_operation/mutations/mutations.dart' as mutations;
import '../graphql_operation/queries/readRepositories.dart' as queries;

/// Create a ../local.dart file with YOUR_PERSONAL_ACCESS_TOKEN = '<YOUR_PERSONAL_ACCESS_TOKEN>'
/// to make the example work
import '../local.dart' show YOUR_PERSONAL_ACCESS_TOKEN;

class GraphQLWidgetScreen extends StatelessWidget {
  const GraphQLWidgetScreen() : super();
  @override
  Widget build(BuildContext context) {
    final HttpLink httpLink = HttpLink(
      uri: 'https://api.github.com/graphql',
    );

    final AuthLink authLink = AuthLink(
      getToken: () async => 'Bearer $YOUR_PERSONAL_ACCESS_TOKEN',
    );

    final WebSocketLink websocketLink = WebSocketLink(
      url: 'ws://localhost:8080/ws/graphql',
      config: SocketClientConfig(
          autoReconnect: true, inactivityTimeout: Duration(seconds: 15)),
    );

    // TODO don't think we have to cast here, maybe covariant
    final Link link = authLink.concat(httpLink as Link).concat(websocketLink);

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
      child: const CacheProvider(
        child: MyHomePage(title: 'GraphQL Widget'),
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

                if (result.data == null && result.errors == null) {
                  return const Text(
                      'Both data and errors are null, this is a known bug after refactoring, you might forget to set Github token');
                }

                // result.data can be either a [List<dynamic>] or a [Map<String, dynamic>]
                final List<dynamic> repositories = result.data['viewer']
                    ['repositories']['nodes'] as List<dynamic>;

                return Expanded(
                  child: ListView.builder(
                    itemCount: repositories.length,
                    itemBuilder: (BuildContext context, int index) =>
                        StarrableRepository(
                            repository:
                                repositories[index] as Map<String, Object>),
                  ),
                );
              },
            ),
            Subscription<Map<String, dynamic>>('test', queries.testSubscription,
                builder: ({
              bool loading,
              Map<String, dynamic> payload,
              dynamic error,
            }) {
              return loading
                  ? const Text('Loading...')
                  : Text(payload.toString());
            }),
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
    return StarrableRepositoryState();
  }
}

class StarrableRepositoryState extends State<StarrableRepository> {
  bool loading = false;

  Map<String, Object> extractRepositoryData(Map<String, Object> data) {
    final Map<String, Object> action = data['action'] as Map<String, Object>;

    if (action == null) {
      return null;
    }

    return action['starrable'] as Map<String, Object>;
  }

  bool get viewerHasStarred => widget.repository['viewerHasStarred'] as bool;

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
          title: Text(widget.repository['name'] as String),
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
          final Map<String, Object> updated = Map<String, Object>.from(
              widget.repository)
            ..addAll(extractRepositoryData(result.data as Map<String, Object>));

          cache.write(typenameDataIdFromObject(updated), updated);
        }
      },
      onCompleted: (QueryResult result) {
        showDialog<AlertDialog>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                extractRepositoryData(result.data as Map<String, Object>)[
                        'viewerHasStarred'] as bool
                    ? 'Thanks for your star!'
                    : 'Sorry you changed your mind!',
              ),
              actions: <Widget>[
                SimpleDialogOption(
                  child: const Text('DISMISS'),
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
