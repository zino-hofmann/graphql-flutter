import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:starwars_app/reviews/review_subscription.dart'
    show DisplayReviews;

class PagingReviews extends StatelessWidget {
  static const BottomNavigationBarItem navItem = BottomNavigationBarItem(
    icon: Icon(Icons.description),
    title: Text('Paging'),
  );

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        documentNode: gql(r'''
          query Reviews($page: Int!) {
            reviews(page: $page) {
              page
              reviews {
                id
                episode
                stars
                commentary
              }
            }
          }
        '''),
        variables: {'page': 0},
      ),
      builder: (
        QueryResult result, {
        Refetch refetch,
        FetchMore fetchMore,
      }) {
        if (result.hasException) {
          return Text(result.exception.toString());
        }

        if (result.loading && result.data == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final nextPage = result.data['reviews']['page'] + 1;

        return Column(
          children: <Widget>[
            Expanded(
              child: DisplayReviews(
                reviews: result.data['reviews']['reviews']
                    .cast<Map<String, dynamic>>(),
              ),
            ),
            (result.loading)
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : RaisedButton(
                    onPressed: () {
                      fetchMore(
                        FetchMoreOptions(
                          variables: {'page': nextPage},
                          updateQuery: (existing, newReviews) => ({
                            'reviews': {
                              'page': newReviews['reviews']['page'],
                              'reviews': [
                                ...existing['reviews']['reviews'],
                                ...newReviews['reviews']['reviews']
                              ],
                            }
                          }),
                        ),
                      );
                    },
                    child: Text('LOAD PAGE $nextPage'),
                  ),
          ],
        );
      },
    );
  }
}
