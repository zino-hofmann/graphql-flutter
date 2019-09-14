import 'package:flutter/material.dart';
import 'package:gql/language.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import './review.dart';

class ReviewFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Subscription<Map<String, dynamic>>(
      'reviewAdded',
      parseString(r'''
        subscription reviewAdded {
          reviewAdded {
            stars, commentary, episode
          }
        }
      '''),
      builder: ({dynamic loading, dynamic payload, dynamic error}) {
        if (error != null) {
          return Text(error.toString());
        }

        if (loading == true) {
          return Center(
            child: const CircularProgressIndicator(),
          );
        }
        return ReviewList(newReview: payload as Map<String, dynamic>);
      },
    );
  }
}

class ReviewList extends StatefulWidget {
  const ReviewList({@required this.newReview});

  final Map<String, dynamic> newReview;

  @override
  _ReviewListState createState() => _ReviewListState();
}

class _ReviewListState extends State<ReviewList> {
  List<Map<String, dynamic>> reviews;

  @override
  void initState() {
    reviews = widget.newReview != null ? [widget.newReview] : [];
    super.initState();
  }

  @override
  void didUpdateWidget(ReviewList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!reviews.contains(widget.newReview)) {
      setState(() {
        reviews.insert(0, widget.newReview);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: reviews
          .map(displayReview)
          .map<Widget>((String s) => Card(
                child: Container(
                  padding: const EdgeInsets.all(15.0),
                  height: 150,
                  child: Text(s),
                ),
              ))
          .toList(),
    );
  }
}
