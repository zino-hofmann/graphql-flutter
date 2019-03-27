import 'package:flutter/material.dart';

import 'bloc.dart' show Bloc, Repo;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GraphQL Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'GraphQL Flutter Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({
    Key key,
    this.title,
  })  : bloc = Bloc(),
        super(key: key);

  final String title;
  final Bloc bloc;

  @override
  _MyHomePageState createState() => _MyHomePageState(bloc);
}

class _MyHomePageState extends State<MyHomePage> {
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
              builder: (BuildContext context,
                  AsyncSnapshot<List<Repo>> snapshot) {
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
    return StreamBuilder<bool>(
      stream: bloc.toggleStarLoadingStream,
      initialData: false,
      builder: (BuildContext context, AsyncSnapshot<bool> result) {
        final bool loading = result.data;
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
