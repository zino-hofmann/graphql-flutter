import 'package:flutter/material.dart';
import './client_provider.dart';
import './episode/episode_page.dart';

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
  int _selectedIndex = 0;

  void _navigateTo(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _selectedIndex == 1 ? Text('') : EpisodePage(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          EpisodePage.navItem,
          EpisodePage.navItem,
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _navigateTo,
      ),
    );
  }
}
