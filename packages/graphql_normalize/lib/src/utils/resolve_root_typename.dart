import 'package:collection/collection.dart' show IterableExtension;
import 'package:gql/ast.dart';
import '../policies/type_policy.dart';

final defaultRootTypenames = {
  OperationType.query: 'Query',
  OperationType.mutation: 'Mutation',
  OperationType.subscription: 'Subscription',
};

String typenameForOperationType(
  OperationType operationType,
  Map<String, TypePolicy> typePolicies,
) {
  switch (operationType) {
    case OperationType.query:
      return typePolicies.entries
              .firstWhereOrNull(
                (entry) => entry.value.queryType,
              )
              ?.key ??
          defaultRootTypenames[OperationType.query]!;
    case OperationType.mutation:
      return typePolicies.entries
              .firstWhereOrNull(
                (entry) => entry.value.mutationType,
              )
              ?.key ??
          defaultRootTypenames[OperationType.mutation]!;
    case OperationType.subscription:
      return typePolicies.entries
              .firstWhereOrNull(
                (entry) => entry.value.subscriptionType,
              )
              ?.key ??
          defaultRootTypenames[OperationType.subscription]!;
  }
}

Set<String> allRootTypenames(Map<String, TypePolicy> typePolicies) {
  return {
    ...OperationType.values.map(
      (operationType) => typenameForOperationType(
        operationType,
        typePolicies,
      ),
    )
  };
}

String resolveRootTypename(
  OperationDefinitionNode operationDefinition,
  Map<String, TypePolicy> typePolicies,
) =>
    typenameForOperationType(
      operationDefinition.type,
      typePolicies,
    );
