import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'models.dart';

@immutable
abstract class MyGithubReposEvent extends Equatable {
  //TODO refactoring the props
  MyGithubReposEvent([List props = const []]) : super();
}

// load your repositories
class LoadMyRepos extends MyGithubReposEvent {
  // the number of repositories to load, default is 50
  final int numOfReposToLoad;

  LoadMyRepos({this.numOfReposToLoad: 50}) : super([numOfReposToLoad]);

  @override
  String toString() => 'LoadMyRepos';

  @override
  // TODO: implement props
  List<Object?> get props => throw UnimplementedError();
}

// update a repo with new mutation status
class MutateToggleStar extends MyGithubReposEvent {
  // the number of repositories to load, default is 50
  final Repo? repo;

  MutateToggleStar({this.repo}) : super([repo]);

  @override
  String toString() => 'MutateToggleStar';

  @override
  // TODO: implement props
  List<Object?> get props => throw UnimplementedError();
}

// update a repo with new mutation status
// class UpdateReposAfterMutations extends MyGithubReposEvent {
//   // the number of repositories to load, default is 50
//   final Repo repo;

//   UpdateReposAfterMutations({this.repo}) : super([repo]);

//   @override
//   String toString() => 'UpdateReposAfterMutations';
// }
