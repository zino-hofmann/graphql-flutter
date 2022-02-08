import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../graphql_operation/mutations/mutations.dart' as mutations;
import '../graphql_operation/queries/readRepositories.dart' as queries;
import '../helpers.dart' show withGenericHandling;

// to run the example, replace <YOUR_PERSONAL_ACCESS_TOKEN> with your GitHub token in ../local.dart
import '../local.dart';

class GraphQLWidgetScreen extends StatelessWidget {
  const GraphQLWidgetScreen() : super();

  @override
  Widget build(BuildContext context) {
    var httpLink = HttpLink('https://api.github.com/graphql', defaultHeaders: {
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
        child: MyHomePage(title: 'GraphQL Widget'),
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
  int nRepositories = 50;

  void changeQuery(String number) {
    setState(() {
      nRepositories = int.parse(number);
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
                      'Loading has completed, but both data and errors are null. '
                      'This should never be the case – please open an issue',
                    );
                  }

                  // result.data can be either a [List<dynamic>] or a [Map<String, dynamic>]
                  final repositories = (result.data!['viewer']['repositories']
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
          ],
        ),
      ),
    );
  }
}

class StarrableRepository extends StatelessWidget {
  const StarrableRepository({
    Key? key,
    required this.repository,
    required this.optimistic,
  }) : super(key: key);

  final Map<String, dynamic> repository;
  final bool optimistic;

  /// Extract the repository data for updating the fragment
  Map<String, dynamic>? extractRepositoryData(Map<String, dynamic> data) {
    final action = data['action'] as Map<String, dynamic>?;
    if (action == null) {
      return null;
    }
    return action['starrable'] as Map<String, dynamic>?;
  }

  /// Get whether the repository is currently starred, according to the current Query
  bool? get starred => repository['viewerHasStarred'] as bool?;

  /// Build an optimisticResult based on whether [viewerIsStarrring]
  Map<String, dynamic> expectedResult(bool viewerIsStarrring) =>
      <String, dynamic>{
        'action': {
          'starrable': {
            '__typename': 'Repository',
            'id': repository['id'],
            'viewerHasStarred': viewerIsStarrring,
          }
        }
      };

  OnMutationUpdate get update => (cache, result) {
        if (result!.hasException) {
          print(result.exception);
        } else {
          final updated = {
            ...repository,
            ...extractRepositoryData(result.data!)!,
          };
          cache.writeFragment(
            Fragment(
              document: gql(
                '''
                  fragment fields on Repository {
                    id
                    name
                    viewerHasStarred
                  }
                  ''',
              ),
            ).asRequest(idFields: {
              '__typename': updated['__typename'],
              'id': updated['id'],
            }),
            data: updated,
          );
        }
      };

  @override
  Widget build(BuildContext context) {
    /// While we could toggle between the addStar and removeStar mutations conditionally,
    /// this would discard and rebuild each associated [ObservableQuery]. The side effects would still execute,
    /// but we would not have a way to inspect the mutation results, such as with [_debugLatestResults].
    return Mutation(
      options: MutationOptions(
        document: gql(mutations.addStar),
        update: update,
        onError: (OperationException? error) =>
            _simpleAlert(context, error.toString()),
        onCompleted: (dynamic resultData) =>
            _simpleAlert(context, 'Thanks for your star!'),
        // 'Sorry you changed your mind!',
      ),
      builder: (RunMutation _addStar, QueryResult? addResult) {
        final addStar = () => _addStar({'starrableId': repository['id']},
            optimisticResult: expectedResult(true));
        return Mutation(
          options: MutationOptions(
            document: gql(mutations.removeStar),
            update: update,
            onError: (OperationException? error) =>
                _simpleAlert(context, error.toString()),
            onCompleted: (dynamic resultData) =>
                _simpleAlert(context, 'Sorry you changed your mind!'),
          ),
          builder: (RunMutation _removeStar, QueryResult? removeResult) {
            final removeStar = () => _removeStar(
                {'starrableId': repository['id']},
                optimisticResult: expectedResult(false));

            final anyLoading =
                addResult!.isLoading || removeResult!.isLoading || optimistic;

            return ListTile(
              leading: starred!
                  ? Icon(
                      Icons.star,
                      color: Colors.amber,
                    )
                  : Icon(Icons.star_border),
              trailing: anyLoading ? CircularProgressIndicator() : null,
              title: Text(repository['name'] as String),

              /// uncomment this line to see the actual mutation results
              subtitle: _debugLatestResults(addResult, removeResult!),
              onTap: anyLoading
                  ? null
                  : starred!
                      ? removeStar
                      : addStar,
            );
          },
        );
      },
    );
  }

  // TODO extract these details into better docs on [Policies]
  /// Used for inspecting the mutation results.
  ///
  /// Can be used to observe the behavior in https://github.com/zino-app/graphql-flutter/issues/774,
  /// patched in https://github.com/zino-app/graphql-flutter/pull/795 with the addition of [CacheRereadPolicy].
  ///
  /// To behavior, add the following to the `Mutations` above:
  /// ```dart
  /// fetchPolicy: FetchPolicy.networkOnly,
  /// cacheRereadPolicy: CacheRereadPolicy.mergeOptimistic,
  /// ```
  /// This will cause the mutation results to be rebroadcast from the cache,
  /// merging in the new `Repository.viewerHasStarred` state.
  /// This can be desirable when a mutation result is used merely as a follow-up query.
  Widget? _debugLatestResults(QueryResult add, QueryResult remove) {
    //return null;
    var latestResults = '';
    if (add.data != null) {
      latestResults += 'addResultRepo: ${extractRepositoryData(add.data!)}; ';
    }
    if (remove.data != null) {
      latestResults +=
          'removeResultRepo: ${extractRepositoryData(remove.data!)}; ';
    }
    if (latestResults.isEmpty) {
      return null;
    }
    return Text(latestResults);
  }
}

void _simpleAlert(BuildContext context, String text) => showDialog<AlertDialog>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(text),
          actions: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('DISMISS'),
            )
          ],
        );
      },
    );
