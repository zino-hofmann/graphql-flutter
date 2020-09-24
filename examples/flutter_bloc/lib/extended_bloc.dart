import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graphql/client.dart';

import 'package:graphql_flutter_bloc_example/extended_bloc/repositories_bloc.dart';
import 'package:graphql_flutter_bloc_example/extended_bloc/graphql/event.dart';
import 'package:graphql_flutter_bloc_example/extended_bloc/graphql/state.dart';

class ExtendedBloc extends StatefulWidget {
  @override
  _ExtendedBlocState createState() => _ExtendedBlocState();
}

class _ExtendedBlocState extends State<ExtendedBloc> {
  Completer<void> _refreshCompleter;
  RepositoriesBloc bloc;

  @override
  void initState() {
    super.initState();
    _refreshCompleter = Completer<void>();
    bloc = BlocProvider.of<RepositoriesBloc>(context)..run();
  }

  Future _handleRefreshStart(Bloc bloc) {
    bloc.add(GraphqlRefetchEvent<Map<String, dynamic>>());
    return _refreshCompleter.future;
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }

  void _handleRefreshEnd() {
    _refreshCompleter?.complete();
    _refreshCompleter = Completer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Extended BLOC example'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _handleRefreshStart(bloc),
        child:
            BlocBuilder<RepositoriesBloc, GraphqlState<Map<String, dynamic>>>(
                bloc: bloc,
                builder: (_, state) {
                  Widget child = Container();

                  if (bloc.isLoading) {
                    child = Center(child: CircularProgressIndicator());
                  }

                  if (bloc.hasError) {
                    _handleRefreshEnd();
                    child = ListView(children: [
                      Text(
                        bloc.getError,
                        style: TextStyle(color: Theme.of(context).errorColor),
                      )
                    ]);
                  }

                  if (bloc.hasData) {
                    _handleRefreshEnd();
                    final itemCount =
                        state.data['viewer']['repositories']['nodes'].length;

                    if (itemCount == 0) {
                      child = ListView(children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(Icons.inbox),
                            SizedBox(width: 8),
                            Text('No data'),
                          ],
                        )
                      ]);
                    } else {
                      child = ListView.separated(
                        separatorBuilder: (_, __) => SizedBox(
                          height: 8.0,
                        ),
                        key: PageStorageKey('reports'),
                        itemCount: itemCount,
                        itemBuilder: (BuildContext context, int index) {
                          final pageInfo =
                              state.data['viewer']['repositories']['pageInfo'];

                          if (bloc.shouldFetchMore(index, 1)) {
                            bloc.fetchMore(after: pageInfo['endCursor']);
                          }

                          final node = state.data['viewer']['repositories']
                              ['nodes'][index];

                          Widget tile = ListTile(
                            title: Text(node['name']),
                          );

                          if (bloc.isFetchingMore && index == itemCount - 1) {
                            tile = Column(
                              children: [
                                tile,
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              ],
                            );
                          }

                          return tile;
                        },
                      );
                    }
                  }

                  return AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: child,
                  );
                }),
      ),
    );
  }
}
