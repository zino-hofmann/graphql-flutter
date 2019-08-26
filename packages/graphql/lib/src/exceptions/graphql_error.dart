/// A location where a [GraphQLError] appears.
class Location {
  /// Constructs a [Location] from a JSON map.
  Location.fromJSON(Map<String, int> data)
      : line = data['line'],
        column = data['column'];

  /// The line of the error in the query.
  final int line;

  /// The column of the error in the query.
  final int column;

  @override
  String toString() => '{ line: $line, column: $column }';
}

/// A GraphQL error (returned by a GraphQL server).
class GraphQLError {
  GraphQLError({
    this.raw,
    this.message,
    this.locations,
    this.path,
    this.extensions,
  });

  /// Constructs a [GraphQLError] from a JSON map.
  GraphQLError.fromJSON(this.raw)
      : message = raw['message'] is String
            ? raw['message'] as String
            : 'Invalid server response: message property needs to be of type String',
        locations = raw['locations'] is List<Map<String, int>>
            ? List<Location>.from(
                (raw['locations'] as List<Map<String, int>>).map<Location>(
                  (Map<String, int> location) => Location.fromJSON(location),
                ),
              )
            : null,
        path = raw['path'] as List<dynamic>,
        extensions = raw['extensions'] as Map<String, dynamic>;

  /// The message of the error.
  final dynamic raw;

  /// The message of the error.
  final String message;

  /// Locations where the error appear.
  final List<Location> locations;

  /// The path of the field in error.
  final List<dynamic> path;

  /// Custom error data returned by your GraphQL API server
  final Map<String, dynamic> extensions;

  @override
  String toString() =>
      '$message: ${locations is List ? locations.map((Location l) => '[${l.toString()}]').join('') : "Undefined location"}';
}
