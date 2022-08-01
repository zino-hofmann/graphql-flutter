import 'package:graphql_normalize/utils.dart';

/// Exception occurring when structurally valid data cannot be resolved
/// for an expected field.
class PartialDataException implements Exception {
  PartialDataException({required this.path});

  /// Path to the first unfound subfield.
  ///
  /// Is a list of field names stringified with [FieldKey]
  final List<String> path;

  @override
  String toString() => 'PartialDataException(path: ${path.join(".")})';
}

class MissingKeyFieldException implements Exception {}
