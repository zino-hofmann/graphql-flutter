import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../graphql_operation/mutations/mutations.dart' as mutations;
import '../graphql_operation/queries/readRepositories.dart' as queries;
import '../helpers.dart' show withGenericHandling;

// ignore: uri_does_not_exist
import '../local.dart';

const bool ENABLE_WEBSOCKETS = false;

class GraphQLWidgetScreen extends StatelessWidget {
  const GraphQLWidgetScreen() : super();

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
    if (ENABLE_WEBSOCKETS) {
      final WebSocketLink websocketLink = WebSocketLink(
        url: 'ws://localhost:8080/ws/graphql',
        config: SocketClientConfig(
            autoReconnect: true, inactivityTimeout: Duration(seconds: 15)),
      );

      link = link.concat(websocketLink);
    }

    final ValueNotifier<GraphQLClient> client = ValueNotifier<GraphQLClient>(
      GraphQLClient(
        cache: OptimisticCache(
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
                documentNode: gql(queries.readRepositories),
                variables: <String, dynamic>{
                  'nRepositories': nRepositories,
                },
                //pollInterval: 10,
              ),
              builder: withGenericHandling(
                (QueryResult result, {refetch, fetchMore}) {
                  if (result.data == null && !result.hasException) {
                    return const Text(
                        'Both data and errors are null, this is a known bug after refactoring, you might forget to set Github token');
                  }

                  // result.data can be either a [List<dynamic>] or a [Map<String, dynamic>]
                  final List<LazyCacheMap> repositories = (result.data['viewer']
                          ['repositories']['nodes'] as List<dynamic>)
                      .cast<LazyCacheMap>();

                  return Expanded(
                    child: ListView.builder(
                      itemCount: repositories.length,
                      itemBuilder: (BuildContext context, int index) {
                        return StarrableRepository(
                            repository: repositories[index]);
                      },
                    ),
                  );
                },
              ),
            ),
            ENABLE_WEBSOCKETS
                ? Subscription<Map<String, dynamic>>(
                    'test', queries.testSubscription, builder: ({
                    bool loading,
                    Map<String, dynamic> payload,
                    dynamic error,
                  }) {
                    return loading
                        ? const Text('Loading...')
                        : Text(payload.toString());
                  })
                : const Text(''),
          ],
        ),
      ),
    );
  }
}

class StarrableRepository extends StatelessWidget {
  const StarrableRepository({
    Key key,
    @required this.repository,
  }) : super(key: key);

  final Map<String, Object> repository;

  Map<String, Object> extractRepositoryData(Object data) {
    final Map<String, Object> action =
        (data as Map<String, Object>)['action'] as Map<String, Object>;
    if (action == null) {
      return null;
    }
    return action['starrable'] as Map<String, Object>;
  }

  bool get starred => repository['viewerHasStarred'] as bool;
  bool get optimistic => (repository as LazyCacheMap).isOptimistic;

  Map<String, dynamic> get expectedResult => <String, dynamic>{
        'action': <String, dynamic>{
          'starrable': <String, dynamic>{'viewerHasStarred': !starred}
        }
      };

  @override
  Widget build(BuildContext context) {
    return Mutation(
      options: MutationOptions(
        documentNode: gql(starred ? mutations.removeStar : mutations.addStar),
        update: (Cache cache, QueryResult result) {
          if (result.hasException) {
            print(result.exception);
          } else {
            final Map<String, Object> updated =
                Map<String, Object>.from(repository)
                  ..addAll(extractRepositoryData(result.data));
            cache.write(typenameDataIdFromObject(updated), updated);
          }
        },
        onError: (OperationException error) {
          showDialog<AlertDialog>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(error.toString()),
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
        },
        onCompleted: (dynamic resultData) {
          showDialog<AlertDialog>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(
                  extractRepositoryData(resultData)['viewerHasStarred'] as bool
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
        },
      ),
      builder: (RunMutation toggleStar, QueryResult result) {
        return ListTile(
          leading: starred
              ? const Icon(
                  Icons.star,
                  color: Colors.amber,
                )
              : const Icon(Icons.star_border),
          trailing: result.loading || optimistic
              ? const CircularProgressIndicator()
              : null,
          title: Text(repository['name'] as String),
          onTap: () {
            toggleStar(
              <String, dynamic>{
                'starrableId': repository['id'],
              },
              optimisticResult: expectedResult,
            );
          },
        );
      },
    );
  }
}
