import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:graphql/client.dart';
import 'package:graphql_flutter/src/widgets/hooks/graphql_client.dart';
import 'package:graphql_flutter/src/widgets/hooks/subscription.dart';

/// Creats a subscription with [GraphQLClient.subscribe].
///
/// The [builder] is passed a [QueryResult] with only the **most recent**
/// `data`. [ResultAccumulator] can be used to accumulate results.
///
/// [onSubscriptionResult] can be used to react to changes,
/// and has access to the `client`.
///
/// {@tool snippet}
///
/// Excerpt from the starwars example using [ResultAccumulator]
///
/// ```dart
/// class ReviewFeed extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Subscription(
///       options: SubscriptionOptions(
///         document: gql(
///           r'''
///             subscription reviewAdded {
///               reviewAdded {
///                 stars, commentary, episode
///               }
///             }
///           ''',
///         ),
///       ),
///       builder: (result) {
///         if (result.hasException) {
///           return Text(result.exception.toString());
///         }
///
///         if (result.isLoading) {
///           return Center(
///             child: const CircularProgressIndicator(),
///           );
///         }
///         return ResultAccumulator.appendUniqueEntries(
///           latest: result.data,
///           builder: (context, {results}) => DisplayReviews(
///             reviews: results.reversed.toList(),
///           ),
///         );
///       },
///     );
///   }
/// }
/// ```
/// {@end-tool}
class Subscription<TParsed> extends HookWidget {
  const Subscription({
    required this.options,
    required this.builder,
    this.onSubscriptionResult,
    Key? key,
  }) : super(key: key);

  final SubscriptionOptions<TParsed> options;
  final SubscriptionBuilder<TParsed> builder;
  final OnSubscriptionResult<TParsed>? onSubscriptionResult;

  @override
  Widget build(BuildContext context) {
    final client = useGraphQLClient();
    return SubscriptionOnClient(
      client: client,
      options: options,
      builder: builder,
    );
  }
}

/// Creats a subscription widget like [Subscription] but
/// with an external client.
class SubscriptionOnClient<TParsed> extends HookWidget {
  const SubscriptionOnClient({
    required this.client,
    required this.options,
    required this.builder,
    this.onSubscriptionResult,
    Key? key,
  }) : super(key: key);

  final GraphQLClient client;
  final SubscriptionOptions<TParsed> options;
  final SubscriptionBuilder<TParsed> builder;
  final OnSubscriptionResult<TParsed>? onSubscriptionResult;

  @override
  Widget build(BuildContext context) {
    final result = useSubscriptionOnClient<TParsed>(
      client,
      options,
      onSubscriptionResult: onSubscriptionResult,
    );
    return builder(result);
  }
}
