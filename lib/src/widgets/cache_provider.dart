// import 'package:flutter/material.dart';
// import '../client.dart';

// class CacheProvider extends StatefulWidget {
//   const CacheProvider({
//     Key key,
//     @required this.child,
//   }) : super(key: key);

//   final Widget child;

//   @override
//   _CacheProviderState createState() => new _CacheProviderState();
// }

// class _CacheProviderState extends State<CacheProvider>
//     with WidgetsBindingObserver {
//   @override
//   void initState() {
//     super.initState();

//     client.cache.restore();

//     WidgetsBinding.instance.addObserver(this);
//   }

//   @override
//   void dispose() {
//     super.dispose();

//     WidgetsBinding.instance.removeObserver(this);
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     switch (state) {
//       case AppLifecycleState.inactive:
//         client.cache.save();
//         break;

//       case AppLifecycleState.paused:
//         client.cache.save();
//         break;

//       case AppLifecycleState.suspending:
//         break;

//       case AppLifecycleState.resumed:
//         client.cache.restore();
//         break;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return widget.child;
//   }
// }
