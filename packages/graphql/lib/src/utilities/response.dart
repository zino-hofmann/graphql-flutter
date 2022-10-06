import 'package:graphql/src/core/_base_options.dart';
import 'package:graphql/src/core/core.dart';
import 'package:graphql/src/exceptions.dart';

QueryResult<TParsed> mapFetchResultToQueryResult<TParsed>(
  Response response,
  BaseOptions<TParsed> options, {
  required QueryResultSource source,
}) {
  List<GraphQLError>? errors;
  Map<String, dynamic>? data;
  Map<String, dynamic>? raw;

  // check if there are errors and apply the error policy if so
  // in a nutshell: `ignore` swallows errors, `none` swallows data
  if (response.errors != null && response.errors!.isNotEmpty) {
    switch (options.errorPolicy) {
      case ErrorPolicy.all:
        // handle both errors and data
        errors = response.errors;
        data = response.data;
        break;
      case ErrorPolicy.ignore:
        // ignore errors
        data = response.data;
        break;
      case ErrorPolicy.none:
      default:
        // TODO not actually sure if apollo even casts graphql errors in `none` mode,
        // it's also kind of legacy
        errors = response.errors;
        break;
    }
  } else {
    data = response.data;
  }

  raw = response.response;

  return QueryResult(
    options: options,
    data: data,
    context: response.context,
    source: source,
    exception: coalesceErrors(
      graphqlErrors: errors,
      raw: raw['errors'] as List<dynamic>?,
    ),
  );
}
