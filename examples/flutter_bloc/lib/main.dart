import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graphql/client.dart';

import 'package:graphql_flutter_bloc_example/bloc.dart';
import 'package:graphql_flutter_bloc_example/repository.dart';
import 'package:graphql_flutter_bloc_example/blocs/repos/my_repos_bloc.dart';
import 'package:graphql_flutter_bloc_example/extended_bloc/repositories_bloc.dart';
import 'package:graphql_flutter_bloc_example/extended_bloc.dart';

// to run the example, create a file ../local.dart with the content:
// const String YOUR_PERSONAL_ACCESS_TOKEN =
//    '<YOUR_PERSONAL_ACCESS_TOKEN>';
import 'local.dart';

void main() => runApp(MyApp());

final OptimisticCache cache = OptimisticCache(
  dataIdFromObject: typenameDataIdFromObject,
);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        'bloc': (_) => BlocProvider(
              create: (context) => MyGithubReposBloc(
                githubRepository: GithubRepository(
                  client: _client(),
                ),
              ),
              child: BlocPage(),
            ),
        'extended-bloc': (_) => BlocProvider(
              create: (context) => RepositoriesBloc(
                client: _client(),
              ),
              child: ExtendedBloc(),
            )
      },
      home: Home(),
    );
  }

  GraphQLClient _client() {
    final HttpLink _httpLink = HttpLink(
      uri: 'https://api.github.com/graphql',
    );

    final AuthLink _authLink = AuthLink(
      getToken: () => 'Bearer $YOUR_PERSONAL_ACCESS_TOKEN',
    );

    final Link _link = _authLink.concat(_httpLink);

    return GraphQLClient(
      cache: cache,
      link: _link,
    );
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select example"),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('BLOC example'),
            onTap: () => Navigator.of(context).pushNamed('bloc'),
          ),
          Divider(),
          ListTile(
            title: Text('Extended BLOC example'),
            onTap: () => Navigator.of(context).pushNamed('extended-bloc'),
          ),
          Divider(),
        ],
      ),
    );
  }
}
