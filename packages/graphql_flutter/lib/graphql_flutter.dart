library graphql_flutter;

export 'package:graphql/client.dart'
    hide GraphQLCache, NormalizedInMemoryCache, OptimisticCache;

export 'package:graphql_flutter/src/caches.dart';

export 'package:graphql_flutter/src/widgets/cache_provider.dart';
export 'package:graphql_flutter/src/widgets/graphql_consumer.dart';
export 'package:graphql_flutter/src/widgets/graphql_provider.dart';
export 'package:graphql_flutter/src/widgets/mutation.dart';
export 'package:graphql_flutter/src/widgets/query.dart';
export 'package:graphql_flutter/src/widgets/subscription.dart';
