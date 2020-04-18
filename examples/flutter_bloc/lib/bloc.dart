import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/repos/events.dart';
import 'blocs/repos/models.dart';
import 'blocs/repos/my_repos_bloc.dart';
import 'blocs/repos/states.dart';

class BlocPage extends StatefulWidget {
  @override
  _BlocPageState createState() => _BlocPageState();
}

class _BlocPageState extends State<BlocPage> {
  @override
  void initState() {
    super.initState();
    final bloc = BlocProvider.of<MyGithubReposBloc>(context);
    bloc.add(LoadMyRepos(numOfReposToLoad: 50));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Flutter Bloc GraphQL Example"),
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
              textAlign: TextAlign.center,
              onChanged: (String n) {
                final reposBloc = BlocProvider.of<MyGithubReposBloc>(context);
                reposBloc
                    .add(LoadMyRepos(numOfReposToLoad: int.parse(n) ?? 50));
              },
            ),
            SizedBox(
              height: 10,
            ),
            new LoadRepositories(
              bloc: BlocProvider.of<MyGithubReposBloc>(context),
            )
          ],
        ),
      ),
    );
  }
}

class LoadRepositories extends StatelessWidget {
  final MyGithubReposBloc bloc;

  const LoadRepositories({Key key, this.bloc}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyGithubReposBloc, MyGithubReposState>(
      bloc: bloc,
      builder: (BuildContext context, MyGithubReposState state) {
        if (state is ReposLoading) {
          return Expanded(
            child: Container(
              child: Center(
                child: CircularProgressIndicator(
                  semanticsLabel: "Loading ...",
                ),
              ),
            ),
          );
        }

        if (state is ReposNotLoaded) {
          return Text("${state.errors}");
        }

        if (state is ReposLoaded) {
          final List<Repo> repositories = state.results;

          return Expanded(
            child: ListView.builder(
              itemCount: state.results.length,
              itemBuilder: (BuildContext context, int index) =>
                  StarrableRepository(
                repository: repositories[index],
                reposBloc: bloc,
              ),
            ),
          );
        }

        return Text(null);
      },
    );
  }
}

class StarrableRepository extends StatelessWidget {
  const StarrableRepository({
    Key key,
    @required this.repository,
    @required this.reposBloc,
  })  : assert(reposBloc != null),
        assert(repository != null),
        super(key: key);

  final Repo repository;
  final MyGithubReposBloc reposBloc;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _isRepoStarred(),
      trailing: _showLoadingIndicator(),
      title: Text(repository.name),
      onTap: () {
        reposBloc.add(MutateToggleStar(repo: repository));
      },
    );
  }

  Widget _showLoadingIndicator() {
    if (repository.isLoading) {
      return CircularProgressIndicator();
    } else {
      return null;
    }
  }

  Widget _isRepoStarred() {
    if (repository.viewerHasStarred) {
      return Icon(
        Icons.star,
        color: Colors.amber,
      );
    } else {
      return Icon(Icons.star_border);
    }
  }
}
