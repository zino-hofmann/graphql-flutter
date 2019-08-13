import 'dart:async';

import 'package:graphql/client.dart';
import 'package:graphql_flutter_bloc_example/blocs/repos/models.dart';
import 'package:graphql_flutter_bloc_example/graphql_operation/mutations/mutations.dart'
    as mutations;
import 'package:graphql_flutter_bloc_example/graphql_operation/queries/readRepositories.dart'
    as queries;

// to run the example, create a file ../local.dart with the content:
// const String YOUR_PERSONAL_ACCESS_TOKEN =
//    '<YOUR_PERSONAL_ACCESS_TOKEN>';
// ignore: uri_does_not_exist
import 'local.dart';

class GithubRepository {
  GraphQLClient _client;

  GithubRepository() {
    final HttpLink _httpLink = HttpLink(
      uri: 'https://api.github.com/graphql',
    );

    final AuthLink _authLink = AuthLink(
      getToken: () async => 'Bearer $YOUR_PERSONAL_ACCESS_TOKEN',
    );

    final Link _link = _authLink.concat(_httpLink);

    _client = GraphQLClient(
      cache: OptimisticCache(
        dataIdFromObject: typenameDataIdFromObject,
      ),
      link: _link,
    );
  }

  Future<QueryResult> fetchMyRepositories(int numOfRepositories) async {
    final WatchQueryOptions _options = WatchQueryOptions(
      document: queries.readRepositories,
      variables: <String, dynamic>{
        'nRepositories': numOfRepositories,
      },
      pollInterval: 4,
      fetchResults: true,
    );

    return await _client.query(_options);
  }

  Future<QueryResult> toggleRepoStar(Repo repo) async {
    var document =
        repo.viewerHasStarred ? mutations.removeStar : mutations.addStar;

    final MutationOptions _options = MutationOptions(
      document: document,
      variables: <String, String>{
        'starrableId': repo.id,
      },
    );

    return _client.mutate(_options);
  }
}
