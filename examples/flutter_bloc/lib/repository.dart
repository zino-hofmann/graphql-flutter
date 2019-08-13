import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:graphql/client.dart';
import 'package:graphql_flutter_bloc_example/blocs/repos/models.dart';
import 'package:graphql_flutter_bloc_example/graphql_operation/mutations/mutations.dart'
    as mutations;
import 'package:graphql_flutter_bloc_example/graphql_operation/queries/readRepositories.dart'
    as queries;

class GithubRepository {
  final GraphQLClient client;

  GithubRepository({@required this.client}) : assert(client != null);

  Future<QueryResult> getRepositories(int numOfRepositories) async {
    final WatchQueryOptions _options = WatchQueryOptions(
      document: queries.readRepositories,
      variables: <String, dynamic>{
        'nRepositories': numOfRepositories,
      },
      pollInterval: 4,
      fetchResults: true,
    );

    return await client.query(_options);
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

    return await client.mutate(_options);
  }
}
