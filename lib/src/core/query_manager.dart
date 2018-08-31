import 'package:meta/meta.dart';

import 'package:graphql_flutter/src/core/query_options.dart';
import 'package:graphql_flutter/src/core/observable_query.dart';

import 'package:graphql_flutter/src/scheduler/scheduler.dart';

import 'package:graphql_flutter/src/link/link.dart';

class QueryManager {
  final Link link;
  final QueryScheduler scheduler = QueryScheduler();

  int idCounter = 1;

  QueryManager({
    @required this.link,
  });

  ObservableQuery query(QueryOptions options) {
    if (options.document == null) {
      throw new Exception(
          'document option is required. You must specify your GraphQL document in the query options.');
    }

    ObservalbeQueryOptions observalbeQueryOptions = ObservalbeQueryOptions(
      document: options.document,
      variables: options.variables,
      fetchPolicy: options.fetchPolicy,
      errorPolicy: options.errorPolicy,
      pollInterval: options.pollInterval,
      context: options.context,
    );

    ObservableQuery observableQuery = ObservableQuery(
      queryManager: this,
      options: observalbeQueryOptions,
    );

    if (options.pollInterval != null) {
      observableQuery.scheduleOnInterval(
        Duration(
          seconds: options.pollInterval,
        ),
      );
    } else {
      observableQuery.schedule();
    }

    return observableQuery;
  }

  ObservableQuery mutate(MutationOptions options) {
    if (options.document == null) {
      throw Exception(
        'document option is required. You must specify your GraphQL document in the mutaion options.',
      );
    }

    ObservalbeQueryOptions observalbeQueryOptions = ObservalbeQueryOptions(
      document: options.document,
      variables: options.variables,
      fetchPolicy: options.fetchPolicy,
      errorPolicy: options.errorPolicy,
      context: options.context,
    );

    ObservableQuery observableQuery = ObservableQuery(
      queryManager: this,
      options: observalbeQueryOptions,
    );

    return observableQuery;
  }

  int generateQueryId() {
    int requestId = idCounter;

    idCounter++;

    return requestId;
  }
}
