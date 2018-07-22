import 'package:flutter/widgets.dart';

import 'package:graphql_flutter/src/client.dart';

class GraphqlProvider extends StatefulWidget {
  const GraphqlProvider({
    Key key,
    this.client,
    this.child,
  }) : super(key: key);

  final ValueNotifier<Client> client;
  final Widget child;

  static ValueNotifier<Client> of(BuildContext context) {
    _InheritedGraphqlProvider inheritedGraphqlProvider =
        context.inheritFromWidgetOfExactType(_InheritedGraphqlProvider);

    return inheritedGraphqlProvider.client;
  }

  @override
  State<StatefulWidget> createState() => _GraphqlProviderState();
}

class _GraphqlProviderState extends State<GraphqlProvider> {
  void didValueChange() => setState(() {});

  @override
  initState() {
    super.initState();

    widget.client.addListener(didValueChange);
  }

  @override
  dispose() {
    widget.client?.removeListener(didValueChange);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedGraphqlProvider(
      client: widget.client,
      child: widget.child,
    );
  }
}

class _InheritedGraphqlProvider extends InheritedWidget {
  _InheritedGraphqlProvider({
    this.client,
    this.child,
  }) : clientValue = client.value;

  final ValueNotifier<Client> client;
  final Widget child;
  final Client clientValue;

  @override
  bool updateShouldNotify(_InheritedGraphqlProvider oldWidget) {
    return clientValue != oldWidget.clientValue;
  }
}
