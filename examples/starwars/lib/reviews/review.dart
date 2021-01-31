import 'package:meta/meta.dart';
import 'package:flutter/material.dart';

import '../episode/episode.dart';

class Review {
  Review({
    @required this.episode,
    @required this.stars,
    @required this.id,
    this.commentary,
  });

  String id;
  Episode episode;
  int stars;
  String commentary;

  Review copyWith({
    Episode episode,
    int stars,
    String commentary,
  }) {
    return Review(
      id: id,
      episode: episode ?? this.episode,
      stars: stars ?? this.stars,
      commentary: commentary ?? this.commentary,
    );
  }

  Map<String, dynamic> toJson() {
    assert(episode != null && stars != null);

    return <String, dynamic>{
      'episode': episodeToJson(episode),
      'stars': stars,
      'commentary': commentary,
    };
  }

  static Review fromJson(Map<String, dynamic> map) => Review(
        id: map['id'],
        episode: episodeFromJson(map['episode'] as String),
        stars: map['stars'] as int,
        commentary: map['commentary'] as String,
      );
}

const String Function(Object jsonObject) displayReview = getPrettyJSONString;

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
