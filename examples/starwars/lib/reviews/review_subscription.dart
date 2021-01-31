import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import './review.dart';

class ReviewFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Subscription(
      options: SubscriptionOptions(
        document: gql(
          r'''
            subscription reviewAdded {
              reviewAdded {
                stars, commentary, episode
              }
            }
          ''',
        ),
      ),
      builder: (result) {
        if (result.hasException) {
          return Text(result.exception.toString());
        }

        if (result.isLoading) {
          return Center(
            child: const CircularProgressIndicator(),
          );
        }
        return ResultAccumulator.appendUniqueEntries(
          latest: result.data,
          builder: (context, {results}) => DisplayReviews(
            reviews: results.reversed.toList(),
          ),
        );
      },
    );
  }
}
