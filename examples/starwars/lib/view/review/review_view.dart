import 'package:flutter/material.dart';
import 'package:starwars_app/model/review/review.dart';

class DisplayReviews extends StatefulWidget {
  const DisplayReviews({
    Key key,
    @required this.reviews,
  }) : super(key: key);

  final List<Map<String, dynamic>> reviews;

  @override
  _DisplayReviewsState createState() => _DisplayReviewsState();
}

class _DisplayReviewsState extends State<DisplayReviews> {
  List<Map<String, dynamic>> get reviews => widget.reviews;

  Widget displayRaw(Map<String, dynamic> raw) => Card(
        child: Container(
          padding: const EdgeInsets.all(15.0),
          //height: 150,
          child: Text(displayReview(raw)),
        ),
      );

  /*
  // for debugging
  @override
  initState() {
    super.initState();
      print(
        'DisplayReviews.initState() called on $this.\n'
        'this should only happen ONCE on this page, regardless of fetchMore calls, etc.',
      );
  }
  @override
  didUpdateWidget(old) {
    super.didUpdateWidget(old);
      print(
        'DisplayReviews.didUpdateWidget() called on $this.\n'
        'this can happen REPEATEDLY due to fetchMore, etc.',
      );
  }
  */

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0.0),
      child: ListView(
        children: reviews.map<Widget>(displayRaw).toList(),
      ),
    );
  }
}
