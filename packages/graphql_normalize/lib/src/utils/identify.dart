import 'package:graphql_normalize/src/policies/type_policy.dart';
import './resolve_data_id.dart';
import 'constants.dart';

/// Returns the canonical ID for a given object or reference.
String? identify(
  Map data, {
  String referenceKey = kDefaultReferenceKey,
  Map<String, TypePolicy> typePolicies = const {},
  DataIdResolver? dataIdFromObject,
}) =>
    data.containsKey(referenceKey)
        ? data[referenceKey] as String
        : resolveDataId(
            data: Map.from(data),
            typePolicies: typePolicies,
            dataIdFromObject: dataIdFromObject,
          );
