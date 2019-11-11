import 'package:gql/language.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:rxdart/subjects.dart';

import '../graphql_operation/mutations/mutations.dart' as mutations;
import '../graphql_operation/queries/readRepositories.dart' as queries;

// ignore: uri_does_not_exist
import '../local.dart';

class Repo {
  const Repo({this.id, this.name, this.viewerHasStarred});
  final String id;
  final String name;
  final bool viewerHasStarred;
}

class Bloc {
  Bloc() {
    _queryRepo();
    _updateNumberOfRepo.listen((int n) async => _queryRepo(nRepositories: n));
    _toggleStarSubject.listen((Repo t) async {
      _toggleStarLoadingSubject.add(t.id);
      // @todo handle error
      final QueryResult _ = await _mutateToggleStar(t);

      _repoSubject.add(_repoSubject.value.map((Repo e) {
        if (e.id != t.id) {
          return e;
        }
        return Repo(
            id: t.id, name: t.name, viewerHasStarred: !t.viewerHasStarred);
      }).toList());
      _toggleStarLoadingSubject.add(null);
    });
  }

  final BehaviorSubject<List<Repo>> _repoSubject =
      BehaviorSubject<List<Repo>>();
  Stream<List<Repo>> get repoStream => _repoSubject.stream;

  final ReplaySubject<Repo> _toggleStarSubject = ReplaySubject<Repo>();
  Sink<Repo> get toggleStarSink => _toggleStarSubject;

  /// The repo currently loading, if any
  final BehaviorSubject<String> _toggleStarLoadingSubject =
      BehaviorSubject<String>();

  Stream<String> get toggleStarLoadingStream =>
      _toggleStarLoadingSubject.stream;

  final BehaviorSubject<int> _updateNumberOfRepo = BehaviorSubject<int>();

  Sink<int> get updateNumberOfRepoSink => _updateNumberOfRepo;

  static final HttpLink _httpLink = HttpLink(
    uri: 'https://api.github.com/graphql',
  );

  static final AuthLink _authLink = AuthLink(
    // ignore: undefined_identifier
    getToken: () async => 'Bearer $YOUR_PERSONAL_ACCESS_TOKEN',
  );

  static final Link _link = _authLink.concat(_httpLink);

  static final GraphQLClient _client = GraphQLClient(
    cache: NormalizedInMemoryCache(
      dataIdFromObject: typenameDataIdFromObject,
    ),
    link: _link,
  );

  Future<QueryResult> _mutateToggleStar(Repo repo) async {
    final MutationOptions _options = MutationOptions(
      documentNode:
          gql(repo.viewerHasStarred ? mutations.removeStar : mutations.addStar),
      variables: <String, String>{
        'starrableId': repo.id,
      },
//      fetchPolicy: widget.options.fetchPolicy,
//      errorPolicy: widget.options.errorPolicy,
    );

    final QueryResult result = await _client.mutate(_options);
    return result;
  }

  Future<void> _queryRepo({int nRepositories = 50}) async {
    // null is loading
    _repoSubject.add(null);
//    FetchPolicy fetchPolicy = widget.options.fetchPolicy;
//
//    if (fetchPolicy == FetchPolicy.cacheFirst) {
//      fetchPolicy = FetchPolicy.cacheAndNetwork;
//    }
    final WatchQueryOptions _options = WatchQueryOptions(
      documentNode: parseString(queries.readRepositories),
      variables: <String, dynamic>{
        'nRepositories': nRepositories,
      },
//      fetchPolicy: fetchPolicy,
//      errorPolicy: widget.options.errorPolicy,
      pollInterval: 4,
      fetchResults: true,
//      context: widget.options.context,
    );

    final QueryResult result = await _client.query(_options);

    if (result.hasException) {
      _repoSubject.addError(result.exception);
      return;
    }

    // result.data can be either a [List<dynamic>] or a [Map<String, dynamic>]
    final List<dynamic> repositories =
        result.data['viewer']['repositories']['nodes'] as List<dynamic>;

    _repoSubject.add(repositories
        .map((dynamic e) => Repo(
              id: e['id'] as String,
              name: e['name'] as String,
              viewerHasStarred: e['viewerHasStarred'] as bool,
            ))
        .toList());
  }
}
