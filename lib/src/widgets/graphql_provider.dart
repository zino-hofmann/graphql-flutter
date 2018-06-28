import 'package:flutter/widgets.dart';

import '../client.dart';

class GraphqlProvider extends InheritedWidget {
  GraphqlProvider({
    Key key,
    @required this.client,
    @required Widget child,
  }) : super(key: key, child: child);

  final Client client;

  @override
  bool updateShouldNotify(GraphqlProvider oldWidget) {
    return client != oldWidget.client;
  }

  static GraphqlProvider of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(GraphqlProvider);
  }
}
