import "package:meta/meta.dart";

import 'package:gql_exec/gql_exec.dart' show Request;
import 'package:gql/ast.dart' show DocumentNode;

/// A proxy to the normalized data living in our store.
///
/// This interface allows a user to read and write
/// denormalized data which feels natural to the user
/// whilst in the background this data is being converted
/// into the normalized store format.
abstract class GraphQLDataProxy {
  /// Reads a GraphQL query from the root query id.
  Map<String, dynamic> readQuery(Request request, {bool optimistic});

  /// Reads a GraphQL fragment from any arbitrary id.
  ///
  /// If there is more than one fragment in the provided document
  /// then a `fragmentName` must be provided to select the correct fragment.
  Map<String, dynamic> readFragment({
    @required DocumentNode fragment,
    @required Map<String, dynamic> idFields,
    String fragmentName,
    Map<String, dynamic> variables,
    bool optimistic,
  });

  /// Writes a GraphQL query to the root query id,
  /// then [broadcast] changes to watchers unless `broadcast: false`
  ///
  /// [normalize] the given [data] into the cache using graphql metadata from [request]
  ///
  /// Conceptually, this can be thought of as providing a manual execution result
  /// in the form of [data]
  void writeQuery(
    Request request, {
    Map<String, dynamic> data,
    bool broadcast,
  });

  /// Writes a GraphQL fragment to any arbitrary id.
  /// then [broadcast] changes to watchers unless `broadcast: false`
  ///
  /// If there is more than one fragment in the provided document
  /// then a `fragmentName` must be provided to select the correct fragment.
  void writeFragment({
    @required DocumentNode fragment,
    @required Map<String, dynamic> idFields,
    @required Map<String, dynamic> data,
    String fragmentName,
    Map<String, dynamic> variables,
    bool broadcast,
  });
}
