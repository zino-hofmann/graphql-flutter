import 'package:rxdart/subjects.dart';
import 'package:graphql_client/graphql_client.dart';

import '../config.dart' show YOUR_PERSONAL_ACCESS_TOKEN;
import '../graphql_operation/mutations/mutations.dart' as mutations;
import '../graphql_operation/queries/readRepositories.dart' as queries;

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
      _toggleStarLoadingSubject.add(true);
      // @todo handle error
      final QueryResult _ = await _mutateToggleStar(t);

      _repoSubject.add(_repoSubject.value.map((Repo e) {
        if (e.id != t.id) {
          return e;
        }
        return Repo(
            id: t.id, name: t.name, viewerHasStarred: !t.viewerHasStarred);
      }).toList());
      _toggleStarLoadingSubject.add(false);
    });
  }

  final BehaviorSubject<List<Repo>> _repoSubject =
      BehaviorSubject<List<Repo>>();
  Stream<List<Repo>> get repoStream => _repoSubject.stream;

  final ReplaySubject<Repo> _toggleStarSubject = ReplaySubject<Repo>();
  Sink<Repo> get toggleStarSink => _toggleStarSubject;

  final BehaviorSubject<bool> _toggleStarLoadingSubject =
      BehaviorSubject<bool>();
  Stream<bool> get toggleStarLoadingStream => _toggleStarLoadingSubject.stream;

  final BehaviorSubject<int> _updateNumberOfRepo = BehaviorSubject<int>();

  Sink<int> get updateNumberOfRepoSink => _updateNumberOfRepo;

  static final HttpLink _httpLink = HttpLink(
    uri: 'https://api.github.com/graphql',
  );

  static final AuthLink _authLink = AuthLink(
    getToken: () async => 'Bearer $YOUR_PERSONAL_ACCESS_TOKEN',
  );

  static final Link _link = _authLink.concat(_httpLink as Link);

  static final GraphQLClient _client = GraphQLClient(
    cache: NormalizedInMemoryCacheVM(
      dataIdFromObject: typenameDataIdFromObject,
    ),
    link: _link,
  );

  Future<QueryResult> _mutateToggleStar(Repo repo) async {
    final MutationOptions _options = MutationOptions(
      document:
          repo.viewerHasStarred ? mutations.removeStar : mutations.addStar,
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
      document: queries.readRepositories,
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

    if (result.hasErrors) {
      _repoSubject.addError(result.errors);
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

/**
 *
 *
    key: Key(starred.toString()),
    options: MutationOptions(
    document: starred ? mutations.removeStar : mutations.addStar,

    builder: (RunMutation toggleStar, QueryResult result) {


    toggleStar(<String, dynamic>{
    'starrableId': widget.repository['id'],
    });
    ),



    update: (Cache cache, QueryResult result) {
    if (result.hasErrors) {
    print(result.errors);
    } else {
    final Map<String, Object> updated =
    Map<String, Object>.from(widget.repository)
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
    extractRepositoryData(result.data as Map<String, Object>)['viewerHasStarred'] as bool
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
 */
