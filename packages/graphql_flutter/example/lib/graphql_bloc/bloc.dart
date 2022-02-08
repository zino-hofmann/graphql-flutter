import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:rxdart/rxdart.dart';

import '../graphql_operation/mutations/mutations.dart' as mutations;
import '../graphql_operation/queries/readRepositories.dart' as queries;

// to run the example, replace <YOUR_PERSONAL_ACCESS_TOKEN> with your GitHub token in ../local.dart
import '../local.dart';

class Repo {
  const Repo({this.id, this.name, this.viewerHasStarred});
  final String? id;
  final String? name;
  final bool? viewerHasStarred;
}

class Bloc {
  Bloc() {
    _queryRepo();
    _updateNumberOfRepo.listen((int n) async => _queryRepo(nRepositories: n));
    _toggleStarSubject.listen((Repo t) async {
      _toggleStarLoadingSubject.add(t.id);
      // @todo handle error
      final _ = await _mutateToggleStar(t);

      _repoSubject.add(_repoSubject.value!.map((Repo e) {
        if (e.id != t.id) {
          return e;
        }
        return Repo(
            id: t.id, name: t.name, viewerHasStarred: !t.viewerHasStarred!);
      }).toList());
      _toggleStarLoadingSubject.add(null);
    });
  }

  final BehaviorSubject<List<Repo>?> _repoSubject =
      BehaviorSubject<List<Repo>?>();
  Stream<List<Repo>?> get repoStream => _repoSubject.stream;

  final ReplaySubject<Repo> _toggleStarSubject = ReplaySubject<Repo>();
  Sink<Repo> get toggleStarSink => _toggleStarSubject;

  /// The repo currently loading, if any
  final BehaviorSubject<String?> _toggleStarLoadingSubject =
      BehaviorSubject<String?>();

  Stream<String?> get toggleStarLoadingStream =>
      _toggleStarLoadingSubject.stream;

  final BehaviorSubject<int> _updateNumberOfRepo = BehaviorSubject<int>();

  Sink<int> get updateNumberOfRepoSink => _updateNumberOfRepo;

  final GraphQLClient _client = GraphQLClient(
    cache: GraphQLCache(),
    link: HttpLink('https://api.github.com/graphql', defaultHeaders: {
      'Authorization': 'Bearer $YOUR_PERSONAL_ACCESS_TOKEN',
    }),
  );

  Future<QueryResult> _mutateToggleStar(Repo repo) async {
    final _options = MutationOptions(
      document: gql(
          repo.viewerHasStarred! ? mutations.removeStar : mutations.addStar),
      variables: <String, String?>{
        'starrableId': repo.id,
      },
    );

    final result = await _client.mutate(_options);
    return result;
  }

  Future<void> _queryRepo({int nRepositories = 50}) async {
    // null is loading
    _repoSubject.add(null);
    final _options = WatchQueryOptions(
      document: gql(queries.readRepositories),
      variables: <String, dynamic>{
        'nRepositories': nRepositories,
      },
      pollInterval: Duration(seconds: 4),
      fetchResults: true,
    );

    final result = await _client.query(_options);

    if (result.hasException) {
      _repoSubject.addError(result.exception!);
      return;
    }

    // result.data can be either a [List<dynamic>] or a [Map<String, dynamic>]
    final repositories =
        result.data!['viewer']['repositories']['nodes'] as List<dynamic>;

    _repoSubject.add(repositories
        .map((dynamic e) => Repo(
              id: e['id'] as String?,
              name: e['name'] as String?,
              viewerHasStarred: e['viewerHasStarred'] as bool?,
            ))
        .toList());
  }
}
