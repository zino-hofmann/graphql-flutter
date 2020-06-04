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
    final httpLink = HttpLink(
      'https://api.github.com/graphql',
    );

    final authLink = AuthLink(
      // ignore: undefined_identifier
      getToken: () async => 'Bearer $YOUR_PERSONAL_ACCESS_TOKEN',
    );

    var link = authLink.concat(httpLink);

    if (ENABLE_WEBSOCKETS) {
      final websocketLink = WebSocketLink('ws://localhost:8080/ws/graphql');

      link = link.concat(websocketLink);
    }

    final client = ValueNotifier<GraphQLClient>(
      GraphQLClient(
        cache: GraphQLCache(),
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
                document: gql(queries.readRepositories),
                variables: {
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
                  final repositories = (result.data['viewer']['repositories']
                      ['nodes'] as List<dynamic>);

                  return Expanded(
                    child: ListView.builder(
                      itemCount: repositories.length,
                      itemBuilder: (BuildContext context, int index) {
                        return StarrableRepository(
                          repository: repositories[index],
                          optimistic: result.source ==
                              QueryResultSource.optimisticResult,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            ENABLE_WEBSOCKETS
                ? Subscription(
                    options: SubscriptionOptions(
                      document: gql(queries.testSubscription),
                    ),
                    builder: (result) => result.isLoading
                        ? const Text('Loading...')
                        : Text(result.data.toString()),
                  )
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
    @required this.optimistic,
  }) : super(key: key);

  final Map<String, Object> repository;
  final bool optimistic;

  Map<String, Object> extractRepositoryData(Map<String, Object> data) {
    final action = data['action'] as Map<String, Object>;
    if (action == null) {
      return null;
    }
    return action['starrable'] as Map<String, Object>;
  }

  bool get starred => repository['viewerHasStarred'] as bool;

  Map<String, dynamic> get expectedResult => <String, dynamic>{
        'action': {
          '__typename': 'AddStarPayload',
          'starrable': {
            '__typename': 'Repository',
            'id': repository['id'],
            'viewerHasStarred': !starred,
          }
        }
      };

  @override
  Widget build(BuildContext context) {
    return Mutation(
      options: MutationOptions(
        document: gql(starred ? mutations.removeStar : mutations.addStar),
        update: (cache, result) {
          if (result.hasException) {
            print(result.exception);
          } else {
            final updated = {
              ...repository,
              ...extractRepositoryData(result.data),
            };
            cache.writeFragment(
              fragment: gql(
                '''
                  fragment fields on Repository {
                    id
                    name
                    viewerHasStarred
                  }
                ''',
              ),
              idFields: {
                '__typename': updated['__typename'],
                'id': updated['id'],
              },
              data: updated,
              broadcast: false,
            );
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
          trailing: result.isLoading || optimistic
              ? const CircularProgressIndicator()
              : null,
          title: Text(repository['name'] as String),
          onTap: () {
            toggleStar(
              {'starrableId': repository['id']},
              optimisticResult: expectedResult,
            );
          },
        );
      },
    );
  }
}
