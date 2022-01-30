import 'package:equatable/equatable.dart';
import 'package:graphql/client.dart';
import 'package:graphql_flutter_bloc_example/blocs/repos/models.dart';

// TODO this see how make this immutable
abstract class MyGithubReposState extends Equatable {
  List<dynamic> _props = const [];
  MyGithubReposState(List props) {
    _props = props;
  }

  @override
  List<dynamic> get props => _props;
}

class ReposLoading extends MyGithubReposState {
  ReposLoading({List props = const []}) : super(props);

  @override
  String toString() => 'ReposLoading';
}

class ReposLoaded extends MyGithubReposState {
  final List<Repo> results;

  ReposLoaded({required this.results}) : super([results]);

  @override
  String toString() => 'ReposLoaded: { Github Repositories: $results }';

  @override
  // TODO: implement props
  List<Object?> get props => throw UnimplementedError();
}

class ReposNotLoaded extends MyGithubReposState {
  final List<GraphQLError>? errors;

  ReposNotLoaded(this.errors) : super([errors]);

  @override
  String toString() => 'ReposNotLoaded';

  @override
  // TODO: implement props
  List<Object?> get props => throw UnimplementedError();
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
