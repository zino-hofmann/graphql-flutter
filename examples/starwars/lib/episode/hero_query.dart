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
        document: gql(r'''
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
        '''),
        variables: <String, String>{
          'ep': episodeToJson(episode),
        },
      ),
      builder: (
        QueryResult result, {
        Future<QueryResult> Function() refetch,
        FetchMore fetchMore,
      }) {
        // NOTE: a loading message is always sent, but if you're developing locally,
        // the network result might be returned so fast that
        // flutter rebuilds again too quickly for you don't see the loading result on the stream
        print([
          result.source,
          if (result.data != null) result.data['hero']['name']
        ]);
        if (result.hasException) {
          return Text(result.exception.toString());
        }

        return Column(
          children: <Widget>[
            if (result.isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
            if (result.data != null)
              Text(
                getPrettyJSONString(result.data),
              ),
            RaisedButton(
              onPressed: result.isNotLoading ? refetch : null,
              child: const Text('REFETCH'),
            ),
          ],
        );
      },
    );
  }
}
