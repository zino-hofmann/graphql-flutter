import 'package:gql/ast.dart';

import 'package:graphql_normalize/src/utils/field_key.dart';
import 'package:graphql_normalize/src/utils/resolve_data_id.dart';
import 'package:graphql_normalize/src/config/normalization_config.dart';
import 'package:graphql_normalize/src/denormalize_node.dart';

class FieldFunctionOptions {
  final NormalizationConfig _config;

  /// The FieldNode object used to read this field.
  final FieldNode field;

  /// Any variables passed to the query that read this field
  final Map<String, dynamic> variables;

  /// The final argument values passed to the field, after applying variables.
  final Map<String, dynamic> args;

  FieldFunctionOptions({
    required this.field,
    required NormalizationConfig config,
  })  : _config = config,
        variables = config.variables,
        args = argsWithValues(config.variables, field.arguments);

  /// Returns whether or not this object is a reference to a normalized object.
  bool isReference(Map<String, dynamic> object) =>
      object.containsKey(_config.referenceKey);

  /// Returns a reference for the given object
  Map<String, dynamic> toReference(Map<String, dynamic> object) => {
        _config.referenceKey: resolveDataId(
          data: object,
          typePolicies: _config.typePolicies,
          dataIdFromObject: _config.dataIdFromObject,
        )
      };

  /// Returns denormalized data for the given [field] and normalized [data], recursively resolving any references.
  T? readField<T>(FieldNode field, Object? data) => denormalizeNode(
        selectionSet: field.selectionSet,
        dataForNode: data,
        config: NormalizationConfig(
          read: _config.read,
          variables: _config.variables,
          typePolicies: _config.typePolicies,
          referenceKey: _config.referenceKey,
          fragmentMap: _config.fragmentMap,
          dataIdFromObject: _config.dataIdFromObject,
          addTypename: _config.addTypename,
          allowPartialData: true,
          possibleTypes: _config.possibleTypes,
        ),
      ) as T?;
}

typedef FieldReadFunction<TExisting, TReadResult> = TReadResult Function(
  TExisting existing,
  FieldFunctionOptions options,
);

typedef FieldMergeFunction<TExisting, TIncoming> = TExisting Function(
  TExisting existing,
  TIncoming incoming,
  FieldFunctionOptions options,
);

class FieldPolicy<TExisting, TIncoming, TReadResult> {
  /// Defines which arguments passed to the field are "important" in the sense
  /// that their values (together with the enclosing entity object) determine
  /// the field's value.
  ///
  /// By default, it is assumed that all field arguments might be important.
  ///
  /// If an empty [List] is provided, all arguments will be ignored.
  List<String>? keyArgs;

  /// Custom function to read existing field
  FieldReadFunction<TExisting, TReadResult>? read;

  /// Custom function to merge into existing field
  FieldMergeFunction<TExisting, TIncoming>? merge;

  FieldPolicy({this.keyArgs, this.read, this.merge});
}
