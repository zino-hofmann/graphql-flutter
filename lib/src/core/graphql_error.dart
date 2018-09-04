/// A location where a [GraphQLError] appears.
class Location {
  /// The line of the error in the query.
  final int line;

  /// The column of the error in the query.
  final int column;

  /// Constructs a [Location] from a JSON map.
  Location.fromJSON(Map<String, int> data)
      : line = data['line'],
        column = data['column'];

  @override
  String toString() => '{ line: $line, column: $column }';
}

/// A GraphQL error (returned by a GraphQL server).
class GraphQLError {
  /// The message of the error.
  final String message;

  /// Locations where the error appear.
  final List<Location> locations;

  /// The path of the field in error.
  final List<dynamic> path;

  /// Custom error data returned by your GraphQL API server
  final Map<String, dynamic> extensions;

  /// Constructs a [GraphQLError] from a JSON map.
  GraphQLError.fromJSON(Map<String, dynamic> data)
      : message = data['message'] as String,
        locations = data['locations'] is List<Map<String, int>>
            ? List.from(
                (data['locations'] as List<Map<String, int>>).map<Location>(
                  (Map<String, int> location) => Location.fromJSON(location),
                ),
              )
            : null,
        path = data['path'] as List<dynamic>,
        extensions = data['extensions'] as Map<String, dynamic>;

  @override
  String toString() =>
      '$message: ${locations is List ? locations.map((l) => '[${l.toString()}]').join('') : ""}';
}
