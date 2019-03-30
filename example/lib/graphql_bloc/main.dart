import 'package:flutter/material.dart';

import 'bloc.dart' show Bloc, Repo;

class GraphQLBlocPatternScreen extends StatefulWidget {
  GraphQLBlocPatternScreen({
    Key key,
    this.title = 'GraphQL Widget',
  })  : bloc = Bloc(),
        super(key: key);

  final String title;
  final Bloc bloc;

  @override
  _MyHomePageState createState() => _MyHomePageState(bloc);
}

class _MyHomePageState extends State<GraphQLBlocPatternScreen> {
  _MyHomePageState(this.bloc);
  final Bloc bloc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
              onChanged: (String n) =>
                  bloc.updateNumberOfRepoSink.add(int.parse(n)),
            ),
            StreamBuilder<List<Repo>>(
              stream: bloc.repoStream,
              builder:
                  (BuildContext context, AsyncSnapshot<List<Repo>> snapshot) {
                if (snapshot.hasError) {
                  return Text('\nErrors: \n  ' +
                      (snapshot.error as List<dynamic>).join(',\n  '));
                }
                if (snapshot.data == null) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final List<Repo> repositories = snapshot.data;

                return Expanded(
                  child: ListView.builder(
                    itemCount: repositories.length,
                    itemBuilder: (BuildContext context, int index) =>
                        StarrableRepository(
                            repository: repositories[index], bloc: bloc),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class StarrableRepository extends StatelessWidget {
  const StarrableRepository({
    Key key,
    @required this.repository,
    @required this.bloc,
  }) : super(key: key);

  final Bloc bloc;
  final Repo repository;

  Map<String, Object> extractRepositoryData(Map<String, Object> data) {
    final Map<String, Object> action = data['action'] as Map<String, Object>;

    if (action == null) {
      return null;
    }

    return action['starrable'] as Map<String, Object>;
  }

  bool get viewerHasStarred => repository.viewerHasStarred;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: bloc.toggleStarLoadingStream,
      initialData: null,
      builder: (BuildContext context, AsyncSnapshot<String> result) {
        final bool loading = repository.id == result.data;
        return ListTile(
          leading: viewerHasStarred
              ? const Icon(
                  Icons.star,
                  color: Colors.amber,
                )
              : const Icon(Icons.star_border),
          trailing: loading ? const CircularProgressIndicator() : null,
          title: Text(repository.name),
          onTap: () {
            bloc.toggleStarSink.add(repository);
          },
        );
      },
    );
  }
}
