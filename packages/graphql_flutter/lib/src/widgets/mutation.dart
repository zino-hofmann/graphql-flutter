import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:graphql/client.dart';
import 'package:graphql_flutter/src/widgets/hooks/mutation.dart';

export 'package:graphql_flutter/src/widgets/hooks/mutation.dart';

typedef MutationBuilder<TParsed> = Widget Function(
  RunMutation<TParsed> runMutation,
  QueryResult<TParsed>? result,
);

/// Builds a [Mutation] widget based on the a given set of [MutationOptions]
/// that streams [QueryResult]s into the [QueryBuilder].
class Mutation<TParsed> extends HookWidget {
  const Mutation({
    final Key? key,
    required this.options,
    required this.builder,
  }) : super(key: key);

  final MutationOptions<TParsed> options;
  final MutationBuilder<TParsed> builder;

  @override
  Widget build(BuildContext context) {
    final result = useMutation(options);
    return builder(result.runMutation, result.result);
  }
}
