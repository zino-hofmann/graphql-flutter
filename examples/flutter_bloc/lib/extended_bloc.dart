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
    bloc = BlocProvider.of<RepositoriesBloc>(context);
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

                  if (state is GraphqlLoading) {
                    child = Center(child: CircularProgressIndicator());
                  }

                  if (state is GraphqlErrorState<Map<String, dynamic>>) {
                    _handleRefreshEnd();
                    child = ListView(children: [
                      Text(
                        parseOperationException(state.error),
                        style: TextStyle(color: Theme.of(context).errorColor),
                      )
                    ]);
                  }

                  if (state is GraphqlLoaded ||
                      state is GraphqlFetchMoreState) {
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

                          if (index == itemCount - 1 &&
                              state is GraphqlLoaded &&
                              pageInfo['hasNextPage']) {
                            bloc.fetchMore(after: pageInfo['endCursor']);
                          }

                          final node = state.data['viewer']['repositories']
                              ['nodes'][index];

                          Widget tile = ListTile(
                            title: Text(node['name']),
                          );

                          if (state is GraphqlFetchMoreState &&
                              index == itemCount - 1) {
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

String parseOperationException(OperationException error) {
  if (error.linkException != null) {
    final exception = error.linkException;

    if (exception is NetworkException) {
      return 'Failed to connect to ${exception.uri}';
    } else {
      return exception.toString();
    }
  }

  if (error.graphqlErrors != null && error.graphqlErrors.isNotEmpty) {
    final errors = error.graphqlErrors;

    return errors.first.message;
  }

  return 'Unknown error';
}
