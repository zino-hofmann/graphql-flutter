import 'package:flutter/material.dart';
import './client_provider.dart';
import './episode.dart';

const String GRAPHQL_ENDPOINT = 'http://127.0.0.1:3000/graphql';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClientProvider(
      uri: GRAPHQL_ENDPOINT,
      child: MaterialApp(
        title: 'Graphql Starwas Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: 'Graphql Starwas Demo Home Page'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Episode currentEpisode = Episode.EMPIRE;

  void _selectEpisode(Episode ep) {
    setState(() {
      currentEpisode = ep;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            EpisodeSelect(
              selected: currentEpisode,
              onSelect: _selectEpisode,
            ),
            Text(
              'Hero for this episode:',
            ),
            HeroForEpisode(
              episode: currentEpisode,
            )
          ],
        ),
      ),
    );
  }
}
