import 'dart:io';

import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

import './client_provider.dart';
import './episode/episode_page.dart';
import './reviews/review_page.dart';
import './reviews/review_page_list.dart';

String get host {
// https://github.com/flutter/flutter/issues/36126#issuecomment-596215587
  if (UniversalPlatform.isAndroid) {
    return '10.0.2.2';
  } else {
    return '127.0.0.1';
  }
}

final graphqlEndpoint = 'http://$host:3000/graphql';
final subscriptionEndpoint = 'ws://$host:3000/subscriptions';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClientProvider(
      uri: graphqlEndpoint,
      subscriptionUri: subscriptionEndpoint,
      child: MaterialApp(
        title: 'Graphql Starwars Demo',
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
