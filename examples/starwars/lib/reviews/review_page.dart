import 'package:flutter/material.dart';

import './review_subscription.dart';

class ReviewsPage extends StatelessWidget {
  static const BottomNavigationBarItem navItem = BottomNavigationBarItem(
    icon: Icon(Icons.star),
    title: Text('Reviews'),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const ListTile(title: Text('Live Stream of Reviews')),
        Expanded(child: ReviewFeed()),
      ],
    );
  }
}
