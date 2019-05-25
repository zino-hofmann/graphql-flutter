import 'package:flutter/material.dart';

import './episode.dart';
import './hero_query.dart';

class EpisodePage extends StatefulWidget {
  static const BottomNavigationBarItem navItem = BottomNavigationBarItem(
    icon: Icon(Icons.movie_filter),
    title: Text('Episodes'),
  );

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
