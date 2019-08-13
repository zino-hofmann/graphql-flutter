import 'package:equatable/equatable.dart';
import 'package:graphql/client.dart';
import 'package:graphql_flutter_bloc_example/blocs/repos/models.dart';
import 'package:meta/meta.dart';

@immutable
abstract class MyGithubReposState extends Equatable {
  MyGithubReposState([List props = const []]) : super(props);
}

class ReposLoading extends MyGithubReposState {
  @override
  String toString() => 'ReposLoading';
}

class ReposLoaded extends MyGithubReposState {
  final List<Repo> results;

  ReposLoaded({@required this.results})
      : assert(results != null),
        super([results]);

  @override
  String toString() => 'ReposLoaded: { Github Repositories: $results }';
}

class ReposNotLoaded extends MyGithubReposState {
  final List<GraphQLError> errors;

  ReposNotLoaded([this.errors]) : super([errors]);

  @override
  String toString() => 'ReposNotLoaded';
}

// class ReposStarToggled extends MyGithubReposState {
//   final QueryResult results;

//   ReposStarToggled([this.results]) : super([results]);

//   @override
//   String toString() => 'ReposStarToggled';
// }

// class ReposStarNotToggled extends MyGithubReposState {
//   @override
//   String toString() => 'ReposStarNotToggled';
// }
