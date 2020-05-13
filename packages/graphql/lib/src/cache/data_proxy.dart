import "package:meta/meta.dart";

import 'package:gql_exec/gql_exec.dart' show Request;
import 'package:gql/ast.dart' show DocumentNode;

class ReadFragmentRequest extends Request {
  /**
     * The root id to be used. This id should take the same form as the
     * value returned by your `dataIdFromObject` function. If a value with your
     * id does not exist in the store, `null` will be returned.
     */
  String id;

  /**
     * A GraphQL document created using the `gql` template string tag from
     * `graphql-tag` with one or more fragments which will be used to determine
     * the shape of data to read. If you provide more than one fragment in this
     * document then you must also specify `fragmentName` to select a single.
     */
  DocumentNode fragment;

  /**
     * The name of the fragment in your GraphQL document to be used. If you do
     * not provide a `fragmentName` and there is only one fragment in your
     * `fragment` document then that fragment will be used.
     */
  String fragmentName;

  /**
     * Any variables that your GraphQL fragments depend on.
     */
  Map<String, dynamic> variables;
}

class WriteRequest extends Request {
  /**
     * The data you will be writing to the store.
     */
  dynamic data;
}

class WriteFragmentRequest extends ReadFragmentRequest implements WriteRequest {
  /**
     * The data you will be writing to the store.
     */
  dynamic data;
}

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
  // TODO the request extension api should have an idFields converter
  Map<String, dynamic> readFragment(
    ReadFragmentRequest request, {
    bool optimistic,
  });

  /// Writes a GraphQL query to the root query id.
  ///
  /// [normalize] the given `data` into the cache using graphql metadata from `request`
  ///
  /// Conceptually, this can be thought of as providing a manual execution result
  /// in the form of `data`
  void writeQuery(
    WriteRequest request,
    Map<String, dynamic> data, {
    bool optimistic = false,
    String queryId,
  });

  /// Writes a GraphQL fragment to any arbitrary id.
  ///
  /// If there is more than one fragment in the provided document
  /// then a `fragmentName` must be provided to select the correct fragment.
  void writeFragment({
    @required DocumentNode fragment,
    @required Map<String, dynamic> idFields,
    @required Map<String, dynamic> data,
    String fragmentName,
    Map<String, dynamic> variables,
    bool optimistic = false,
    String queryId,
  });
}
