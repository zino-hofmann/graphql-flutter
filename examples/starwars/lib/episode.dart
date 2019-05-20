import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

/// The episodes in the Star Wars trilogy
enum Episode {
  NEWHOPE,
  EMPIRE,
  JEDI,
}

String episodeToJson(Episode e) {
  switch (e) {
    case Episode.NEWHOPE:
      return 'NEWHOPE';
    case Episode.EMPIRE:
      return 'EMPIRE';
    case Episode.JEDI:
      return 'JEDI';
    default:
      return null;
  }
}

Episode episodeFromJson(String e) {
  switch (e) {
    case 'NEWHOPE':
      return Episode.NEWHOPE;
    case 'EMPIRE':
      return Episode.EMPIRE;
    case 'JEDI':
      return Episode.JEDI;
    default:
      return null;
  }
}

String format(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

// TODO this uses inline fragments and those are broken
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
      builder: (QueryResult result, {BoolCallback refetch}) {
        if (result.errors != null) {
          return Text(result.errors.toString());
        }

        if (result.loading) {
          return Center(
            child: const CircularProgressIndicator(),
          );
        }
        return Column(
          children: <Widget>[
            Text(getPrettyJSONString(result.data)),
            RaisedButton(
              onPressed: () => print(refetch()),
              child: const Text('REFETCH'),
            ),
          ],
        );
      },
    );
  }
}

typedef OnSelect = void Function(Episode episode);

class EpisodeSelect extends StatelessWidget {
  const EpisodeSelect({
    @required this.onSelect,
    @required this.selected,
  });

  final OnSelect onSelect;
  final Episode selected;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<Episode>(
      value: selected,
      onChanged: onSelect,
      items: Episode.values.map<DropdownMenuItem<Episode>>((Episode value) {
        return DropdownMenuItem<Episode>(
          value: value,
          child: Text(value.toString()),
        );
      }).toList(),
    );
  }
}

String getPrettyJSONString(Object jsonObject) {
  return const JsonEncoder.withIndent('  ').convert(jsonObject);
}
