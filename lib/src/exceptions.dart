/// A location where a [GQLError] appears.
class Location {
  /// The line of the error in the query.
  final int line;

  /// The column of the error in the query.
  final int column;

  /// Constructs a [Location] from a JSON map.
  Location.fromJSON(Map data)
      : line = data['line'],
        column = data['column'];

  @override
  String toString() => '{ line: $line, column: $column }';
}

/// A GQL error (returned by a GQL server).
class GQLError {
  /// The message of the error.
  final String message;

  /// Locations where the error appear.
  final List<Location> locations;

  /// The path of the field in error.
  final List<dynamic> path;

  /// Custom error data returned by your GraphQL API server
  final Map<String, dynamic> extensions;

  /// Constructs a [GQLError] from a JSON map.
  GQLError.fromJSON(Map data)
      : message = data['message'],
        locations = data["locations"] is List
            ? new List.from(
                (data['locations']).map((d) => new Location.fromJSON(d)))
            : null,
        path = data['path'],
        extensions = data['extensions'];

  @override
  String toString() =>
      '$message: ${locations is List ? locations.map((l) => '[${l.toString()}]').join('') : ""}';
}

/// A Exception that is raised if the GQL response has a [GQLError].
class GQLException implements Exception {
  /// The Exception message.
  final String message;

  /// The list of [GQLError] in the response.
  final List<GQLError> gqlErrors;

  /// Creates a new [GQLException].
  ///
  /// It requires a message and a JSON list from a GQL response
  /// (returned by a GQL server).
  GQLException(this.message, List rawGQLError)
      : gqlErrors =
            new List.from(rawGQLError.map((d) => new GQLError.fromJSON(d)));

  @override
  String toString() =>
      '$message: ${gqlErrors.map((e) => '[${e.toString()}]').join('')}';
}

class NoConnectionException implements Exception {}
