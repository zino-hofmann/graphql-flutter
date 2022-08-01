import 'dart:collection';
import 'dart:convert';
import 'package:gql/ast.dart';

import 'package:graphql_normalize/src/policies/field_policy.dart';

/// A utility class for stringifying a field plus variables.
///
/// If the given [FieldPolicy] includes [FieldPolicy.keyArgs], only those
/// arguments will be used to construct the key. If no [FieldPolicy.keyArgs]
/// are defined, all arguments will be included.
class FieldKey {
  final String fieldName;
  final SplayTreeMap<String, dynamic> args;

  FieldKey(
    FieldNode fieldNode,
    Map<String, dynamic> variables,
    FieldPolicy? fieldPolicy,
  )   : fieldName = fieldNode.name.value,
        args = _initArgs(fieldNode, variables, fieldPolicy);

  static SplayTreeMap<String, dynamic> _initArgs(
    FieldNode fieldNode,
    Map<String, dynamic> variables,
    FieldPolicy? fieldPolicy,
  ) {
    final pertinentArguments = fieldPolicy?.keyArgs == null
        ? fieldNode.arguments
        : fieldNode.arguments.where(
            (argument) => fieldPolicy!.keyArgs!.contains(argument.name.value));
    return argsWithValues(variables, pertinentArguments);
  }

  FieldKey.from(
    this.fieldName,
    Map<String, dynamic> args,
  ) : args = SplayTreeMap<String, dynamic>.from(args);

  @override
  bool operator ==(o) => o.toString() == toString();

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() =>
      args.isEmpty ? fieldName : '$fieldName(${json.encode(args)})';

  static FieldKey parse(String keyString) {
    final openingIndex = keyString.indexOf('(');
    final closingIndex = keyString.lastIndexOf(')');
    final name =
        openingIndex == -1 ? keyString : keyString.substring(0, openingIndex);
    final Map<String, dynamic> args = openingIndex == -1
        ? {}
        : json.decode(keyString.substring(openingIndex + 1, closingIndex))
            as Map<String, dynamic>;
    return FieldKey.from(name, args);
  }
}

SplayTreeMap<String, dynamic> argsWithValues(
  Map<String, dynamic> variables,
  Iterable<ArgumentNode> arguments,
) =>
    arguments.fold(
      SplayTreeMap(),
      (map, argument) => map
        ..[argument.name.value] = _resolveValueNode(
          argument.value,
          variables,
        ),
    );

Object? _resolveValueNode(
  ValueNode valueNode,
  Map<String, dynamic> variables,
) {
  if (valueNode is VariableNode) {
    return variables[valueNode.name.value];
  } else if (valueNode is ListValueNode) {
    return valueNode.values
        .map((node) => _resolveValueNode(
              node,
              variables,
            ))
        .toList();
  } else if (valueNode is ObjectValueNode) {
    return {
      for (var field in valueNode.fields)
        field.name.value: _resolveValueNode(
          field.value,
          variables,
        )
    };
  } else if (valueNode is IntValueNode) {
    return int.parse(valueNode.value);
  } else if (valueNode is FloatValueNode) {
    return double.parse(valueNode.value);
  } else if (valueNode is StringValueNode) {
    return valueNode.value;
  } else if (valueNode is BooleanValueNode) {
    return valueNode.value;
  } else if (valueNode is EnumValueNode) {
    return valueNode.name.value;
  } else {
    return null;
  }
}
