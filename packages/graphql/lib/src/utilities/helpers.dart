import 'dart:convert';

import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:http/http.dart' show MultipartFile;
import 'package:normalize/utils.dart';

bool notNull(Object? any) {
  return any != null;
}

Map<String, dynamic>? _recursivelyAddAll(
  Map<String, dynamic>? target,
  Map<String, dynamic>? source,
) {
  target = Map<String, dynamic>.from(target!);
  source!.forEach((String key, dynamic value) {
    if (target!.containsKey(key) &&
        target[key] is Map<String, dynamic> &&
        value != null &&
        value is Map<String, dynamic>) {
      target[key] = _recursivelyAddAll(
        target[key] as Map<String, dynamic>,
        value,
      );
    } else {
      // Lists and nulls overwrite target as if they were normal scalars
      target[key] = value;
    }
  });
  return target;
}

/// Deeply merges `maps` into a new map, merging nested maps recursively.
///
/// Paths in the rightmost maps override those in the earlier ones, so:
/// ```
/// print(deeplyMergeLeft([
///   {'keyA': 'a1'},
///   {'keyA': 'a2', 'keyB': 'b2'},
///   {'keyB': 'b3'}
/// ]));
/// // { keyA: a2, keyB: b3 }
/// ```
///
/// Conflicting [List]s are overwritten like scalars
Map<String, dynamic>? deeplyMergeLeft(
  Iterable<Map<String, dynamic>?> maps,
) {
  // prepend an empty literal for functional immutability
  return (<Map<String, dynamic>?>[{}]..addAll(maps)).reduce(_recursivelyAddAll);
}

/// Parse a GraphQL [document] into a [DocumentNode],
/// automatically adding `__typename`s
///
/// If you want to provide your own document parser or builder,
/// keep in mind that default cache normalization depends heavily on `__typename`s,
/// So you should probably include an [AddTypenameVistor] [transform]
DocumentNode gql(String document) => transform(
      parseString(document),
      [AddTypenameVisitor()],
    );

/// Converts [MultipartFile]s to a string representation containing hashCode. Default argument to [variableSanitizer]
Object? sanitizeFilesForCache(dynamic object) {
  if (object is MultipartFile) {
    return 'MultipartFile(filename=${object.filename} hashCode=${object.hashCode})';
  }
  return object.toJson();
}

typedef SanitizeVariables = Map<String, dynamic>? Function(
  Map<String, dynamic> variables,
);

/// Build a sanitizer for safely writing custom scalar inputs in variable arguments to the cache.
///
/// [sanitizeVariables] is passed to [jsonEncode] as `toEncodable`. The default is  [defaultSanitizeVariables],
/// which convets [MultipartFile]s to a string representation containing hashCode)
SanitizeVariables variableSanitizer(
  Object? Function(Object?)? sanitizeVariables,
) =>
    // TODO use more efficient traversal method
    sanitizeVariables == null
        ? (v) => v
        : (variables) => jsonDecode(
              jsonEncode(
                variables,
                toEncodable: sanitizeVariables,
              ),
            ) as Map<String, dynamic>;
