import 'dart:async';

import 'package:gql/ast.dart';
import 'package:graphql/client.dart';
import 'package:meta/meta.dart';

import 'package:graphql/src/core/query_manager.dart';
import 'package:graphql/src/core/query_options.dart';
import 'package:graphql/src/core/query_result.dart';
import 'package:graphql/src/core/policies.dart';

/// options for fetchmore operations
class FetchMoreOptions {
  FetchMoreOptions({
    @required this.document,
    this.variables = const <String, dynamic>{},
    @required this.updateQuery,
  }) : assert(updateQuery != null);

  DocumentNode document;

  final Map<String, dynamic> variables;

  /// Strategy for merging the fetchMore result data
  /// with the result data already in the cache
  UpdateQuery updateQuery;
}

/// Fetch more results and then merge them with [previousResult]
/// according to [FetchMoreOptions.updateQuery]
///
/// Will add results if [ObservableQuery.queryId] is supplied,
/// and broadcast any cache changes
///
/// This is the **Internal Implementation**,
/// used by [ObservableQuery] and [GraphQLCLient.fetchMore]
Future<QueryResult> fetchMoreImplementation(
  FetchMoreOptions fetchMoreOptions, {
  @required QueryOptions originalOptions,
  @required QueryManager queryManager,
  @required QueryResult previousResult,
  String queryId,
}) async {
  // fetch more and udpate
  assert(fetchMoreOptions.updateQuery != null);

  final document = (fetchMoreOptions.document ?? originalOptions.document);

  assert(
    document != null,
    'Either fetchMoreOptions.document '
    'or the previous QueryOptions must be supplied!',
  );

  final combinedOptions = QueryOptions(
    fetchPolicy: FetchPolicy.noCache,
    errorPolicy: originalOptions.errorPolicy,
    document: document,
    variables: {
      ...originalOptions.variables,
      ...fetchMoreOptions.variables,
    },
  );

  QueryResult fetchMoreResult = await queryManager.query(combinedOptions);

  try {
    // combine the query with the new query, using the function provided by the user
    fetchMoreResult.data = fetchMoreOptions.updateQuery(
      previousResult.data,
      fetchMoreResult.data,
    );
    assert(fetchMoreResult.data != null, 'updateQuery result cannot be null');
    // will add to a stream with `queryId` and rebroadcast if appropriate
    queryManager.addQueryResult(
      originalOptions.asRequest,
      queryId,
      fetchMoreResult,
      writeToCache: originalOptions.fetchPolicy != FetchPolicy.noCache,
    );
  } catch (error) {
    if (fetchMoreResult.hasException) {
      // because the updateQuery failure might have been because of these errors,
      // we just add them to the old errors
      previousResult.exception = coalesceErrors(
        exception: previousResult.exception,
        graphqlErrors: fetchMoreResult.exception.graphqlErrors,
        linkException: fetchMoreResult.exception.linkException,
      );
      return previousResult;
    } else {
      // TODO merge results OperationException
      rethrow;
    }
  }

  return fetchMoreResult;
}
