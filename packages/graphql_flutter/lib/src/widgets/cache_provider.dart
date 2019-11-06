import 'package:flutter/material.dart';

import 'package:graphql/client.dart';

import 'package:graphql_flutter/src/widgets/graphql_provider.dart';

class CacheProvider extends StatefulWidget {
  const CacheProvider({
    final Key key,
    @required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  _CacheProviderState createState() => _CacheProviderState();
}

class _CacheProviderState extends State<CacheProvider>
    with WidgetsBindingObserver {
  GraphQLClient client;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    /// Gets the client from the closest wrapping [GraphqlProvider].
    client = GraphQLProvider.of(context).value;
    assert(client != null);

    client.cache?.restore();

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();

    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    assert(client != null);

    switch (state) {
      // TODO: from @degroote22 in #175: reconsider saving on `inactive`
      // When the app is 'cold-started', save won't be called and
      // restore will run ok.
      case AppLifecycleState.inactive:
        client.cache?.save();
        break;

      case AppLifecycleState.paused:
        client.cache?.save();
        break;

      case AppLifecycleState.resumed:
        client.cache?.restore();
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
