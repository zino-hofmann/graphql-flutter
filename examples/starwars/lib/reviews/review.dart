import 'package:meta/meta.dart';
import 'package:flutter/material.dart';

import '../episode/episode.dart';

class Review {
  Review({
    @required this.episode,
    @required this.stars,
    this.commentary,
  });

  Episode episode;
  int stars;
  String commentary;

  Review copyWith({
    Episode episode,
    int stars,
    String commentary,
  }) {
    return Review(
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
        episode: episodeFromJson(map['episode'] as String),
        stars: map['stars'] as int,
        commentary: map['commentary'] as String,
      );
}

const String Function(Object jsonObject) displayReview = getPrettyJSONString;

class DisplayReviews extends StatelessWidget {
  const DisplayReviews({
    Key key,
    @required this.reviews,
  }) : super(key: key);

  final List<Map<String, dynamic>> reviews;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: reviews
          .map(displayReview)
          .map<Widget>((String s) => Card(
                child: Container(
                  padding: const EdgeInsets.all(15.0),
                  //height: 150,
                  child: Text(s),
                ),
              ))
          .toList(),
    );
  }
}
