import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class EpisodePage extends StatefulWidget {
  @override
  _EpisodePageState createState() => _EpisodePageState();
}

class _EpisodePageState extends State<EpisodePage> {
  Episode currentEpisode = Episode.EMPIRE;

  void _selectEpisode(Episode ep) {
    setState(() {
      currentEpisode = ep;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          EpisodeSelect(
            selected: currentEpisode,
            onSelect: _selectEpisode,
          ),
          const Text(
            'Hero for this episode:',
          ),
          HeroForEpisode(
            episode: currentEpisode,
          )
        ],
      ),
    );
  }
}

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
          'ep': _episodeToJson(episode),
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

/// The episodes in the Star Wars trilogy
enum Episode {
  NEWHOPE,
  EMPIRE,
  JEDI,
}

String _episodeToJson(Episode e) {
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

Episode _episodeFromJson(String e) {
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
