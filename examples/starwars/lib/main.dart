import 'dart:io';

import 'package:flutter/material.dart';

import './client_provider.dart';
import './episode/episode_page.dart';
import './reviews/review_page.dart';
import './reviews/review_page_list.dart';

String get host {
  if (Platform.isAndroid) {
    return '10.0.2.2';
  } else {
    return 'localhost';
  }
}

final String GRAPHQL_ENDPOINT = 'http://$host:3000/graphql';
final String SUBSCRIPTION_ENDPOINT = 'ws://$host:3000/subscriptions';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClientProvider(
      uri: GRAPHQL_ENDPOINT,
      subscriptionUri: SUBSCRIPTION_ENDPOINT,
      child: MaterialApp(
        title: 'Graphql Starwas Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: 'Graphql Starwars Demo'),
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
      body: [EpisodePage(), ReviewsPage(), PagingReviews()][_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          EpisodePage.navItem,
          ReviewsPage.navItem,
          PagingReviews.navItem,
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _navigateTo,
      ),
    );
  }
}
