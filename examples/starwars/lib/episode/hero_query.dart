import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import './episode.dart';

class HeroForEpisode extends StatelessWidget {
  const HeroForEpisode({@required this.episode});

  final Episode episode;

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: r'''
          query HeroForEpisode($ep: Episode!) {
            hero(episode: $ep) {
              __typename
              name
              ... on Droid {
                primaryFunction
              }
              ... on Human {
                height
                homePlanet
              }
            }
          }
        ''',
        variables: <String, String>{
          'ep': episodeToJson(episode),
        },
      ),
      builder: (
        QueryResult result, {
        BoolCallback refetch,
        FetchMore fetchMore,
      }) {
        if (result.loading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (result.hasException) {
          return Text(result.exception.toString());
        }
        return Column(
          children: <Widget>[
            Text(getPrettyJSONString(result.data)),
            RaisedButton(
              onPressed: refetch,
              child: const Text('REFETCH'),
            ),
          ],
        );
      },
    );
  }
}
