import 'package:gql_exec/gql_exec.dart' show Request;
import 'package:graphql/src/exceptions/exceptions_next.dart';

import './fragment.dart';

// massive example taken from 'all methods with exposition' in graphql_client_test
/// A proxy to the normalized data living in our store.
///
/// This interface allows a user to read and write
/// denormalized data which feels natural to the user
/// whilst in the background this data is being converted
/// into the normalized store format.
///
/// Here is a complete and expository rundown of the usage of [GraphQLDataProxy]'s methods
/// ([readQuery], [writeQuery], [readFragment], [writeFragment]), given an instance of `GraphQLClient client` as an example
/// ```dart
/// /// entity identifiers for normalization
/// final idFields = {'__typename': 'MyType', 'id': 1};
///
/// /// The direct cache API uses `gql_link` Requests directly
/// /// These can also be obtained via `options.asRequest` from any `Options` object,
/// /// or via `Operation(document: gql(...)).asRequest()`
/// final queryRequest = Request(
///   operation: Operation(
///     document: gql(
///       r'''{
///         someField {
///           __typename,
///           id,
///           myField
///         }
///       }''',
///     ),
///   ),
/// );
///
/// final queryData = {
///   'someField': {
///     ...idFields,
///     'myField': 'originalValue',
///   },
/// };
///
/// /// `broadcast: true` (the default) would rebroadcast cache updates to all safe instances of `ObservableQuery`
/// /// **NOTE**: only `GraphQLClient` can immediately call for a query rebroadcast. if you request a rebroadcast directly
/// /// from the cache, it still has to wait for the client to check in on it
/// client.writeQuery(queryRequest, data: queryData, broadcast: false);
///
/// /// `optimistic: true` (the default) integrates optimistic data
/// /// written to the cache into your read.
/// expect(
///     client.readQuery(queryRequest, optimistic: false), equals(queryData));
///
/// /// While fragments are never executed themselves, we provide a `gql_link`-like API for consistency.
/// /// These can also be obtained via `Fragment(document: gql(...)).asRequest()`.
/// final fragmentRequest = FragmentRequest(
///     fragment: Fragment(
///       document: gql(
///         r'''
///           fragment mySmallSubset on MyType {
///             myField,
///             someNewField
///           }
///         ''',
///       ),
///     ),
///     idFields: idFields);
///
/// /// We've specified `idFields` and are only editing a subset of the data
/// final fragmentData = {
///   'myField': 'updatedValue',
///   'someNewField': [
///     {'newData': false}
///   ],
/// };
///
/// /// We didn't disable `broadcast`, so all instances of `ObservableQuery` will be notified of any changes
/// client.writeFragment(fragmentRequest, data: fragmentData);
///
/// /// __typename is automatically included in all reads
/// expect(
///   client.readFragment(fragmentRequest),
///   equals({
///     '__typename': 'MyType',
///     ...fragmentData,
///   }),
/// );
///
/// final updatedQueryData = {
///   'someField': {
///     ...idFields,
///     'myField': 'updatedValue',
///   },
/// };
///
/// /// `myField` is updated, but we don't have `someNewField`, as expected.
/// expect(client.readQuery(queryRequest), equals(updatedQueryData));
/// ```
abstract class GraphQLDataProxy {
  /// Reads a GraphQL query from the root query id.
  Map<String, dynamic>? readQuery(Request request, {bool optimistic});

  /// Reads a GraphQL fragment from any arbitrary id.
  ///
  /// If there is more than one fragment in the provided document
  /// then a `fragmentName` must be provided to `fragmentRequest.fragment`
  /// to select the correct fragment.
  Map<String, dynamic>? readFragment(
    FragmentRequest fragmentRequest, {
    bool optimistic,
  });

  /// Writes a GraphQL query to the root query id,
  /// then [broadcast] changes to watchers unless `broadcast: false`
  ///
  /// [normalize] the given [data] into the cache using graphql metadata from [request].
  /// Conceptually, this can be thought of as providing a manual execution result
  /// in the form of [data]
  ///
  /// For complex `normalize` type policies that involve custom reads,
  /// `optimistic` will be the default.
  ///
  /// Will throw a [PartialDataException] if the [data] structure
  /// doesn't match that of the [request] `operation.document`,
  /// or a [CacheMisconfigurationException] if the write fails for some other reason.
  void writeQuery(
    Request request, {
    required Map<String, dynamic> data,
    bool? broadcast,
  });

  /// Writes a GraphQL fragment to any arbitrary id.
  /// then [broadcast] changes to watchers unless `broadcast: false`
  ///
  /// If there is more than one fragment in the provided document
  /// then a `fragmentName` must be provided to `fragmentRequest.fragment`
  /// to select the correct fragment.
  ///
  /// For complex `normalize` type policies that involve custom reads,
  /// `optimistic` will be the default.
  ///
  /// Will throw a [PartialDataException] if the [data] structure
  /// doesn't match that of the [fragmentRequest] `fragment.document`,
  /// or a [CacheMisconfigurationException] if the write fails for some other reason.
  void writeFragment(
    FragmentRequest fragmentRequest, {
    required Map<String, dynamic> data,
    bool? broadcast,
  });
}
