import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

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
    final result = useSubscription<TParsed>(
      options,
      onSubscriptionResult: onSubscriptionResult,
    );
    return builder(result);
  }
}
