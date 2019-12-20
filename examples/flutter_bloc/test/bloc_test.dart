import 'dart:convert';

import 'package:graphql/client.dart';
import 'package:graphql_flutter_bloc_example/blocs/repos/events.dart';
import 'package:graphql_flutter_bloc_example/blocs/repos/models.dart';
import 'package:graphql_flutter_bloc_example/blocs/repos/my_repos_bloc.dart';
import 'package:graphql_flutter_bloc_example/blocs/repos/states.dart';
import 'package:graphql_flutter_bloc_example/repository.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';

class MockGithubRepository extends Mock implements GithubRepository {}

const data = """
{
  "data": {
    "viewer": {
      "repositories": {
        "nodes": [
          {
            "__typename": "Repository",
            "id": "MDEwOlJlcG9zaXRvcnkyNDgzOTQ3NA==",
            "name": "pq",
            "viewerHasStarred": false
          },
          {
            "__typename": "Repository",
            "id": "MDEwOlJlcG9zaXRvcnkzMjkyNDQ0Mw==",
            "name": "go-evercookie",
            "viewerHasStarred": false
          },
          {
            "__typename": "Repository",
            "id": "MDEwOlJlcG9zaXRvcnkzNTA0NjgyNA==",
            "name": "watchbot",
            "viewerHasStarred": false
          }
        ]
      }
    }
  }
}
""";

Map<String, dynamic> decodeGithubResponse = jsonDecode(data);
final List<dynamic> mockedGithubRepos = decodeGithubResponse['data']['viewer']
    ['repositories']['nodes'] as List<dynamic>;

final List<Repo> mockedMappedRepos = mockedGithubRepos
    .map((dynamic e) => Repo(
          id: e['id'] as String,
          name: e['name'] as String,
          viewerHasStarred: e['viewerHasStarred'] as bool,
        ))
    .toList();

void main() {
  group('GithubReposBloc', () {
    MyGithubReposBloc repoBloc;
    MockGithubRepository githubRepository;

    final numOfRepos = 50;

    setUp(() {
      githubRepository = MockGithubRepository();
      repoBloc = MyGithubReposBloc(
        githubRepository: githubRepository,
      );
    });

    test('initial state is loading', () {
      expect(repoBloc.initialState, ReposLoading());
    });

    group('Fetch Repositories', () {
      test('fetch repositories', () {
        final results = QueryResult(
          data: decodeGithubResponse['data'],
          errors: null,
          loading: false,
        );

        when(
          githubRepository.getRepositories(numOfRepos),
        ).thenAnswer(
          (_) => Future.value(results),
        );

        final expected = [
          ReposLoading(),
          ReposLoaded(results: mockedMappedRepos),
        ];

        expectLater(
          repoBloc.state,
          emitsInOrder(expected),
        );

        repoBloc.dispatch(LoadMyRepos(numOfReposToLoad: numOfRepos));
      });
    });
  });
}
