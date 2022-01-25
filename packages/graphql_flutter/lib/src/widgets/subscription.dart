import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

typedef OnSubscriptionResult<TParsed> = void Function(
  QueryResult<TParsed> subscriptionResult,
  GraphQLClient? client,
);

typedef SubscriptionBuilder<TParsed> = Widget Function(
    QueryResult<TParsed> result);

/// Creats a subscription with [GraphQLClient.subscribe].
///
/// The [builder] is passed a [QueryResult] with only the **most recent**
/// `data`. [ResultAccumulator] can be used to accumulate results.
///
/// [onSubscriptionResult] can be used to react to changes,
/// and has access to the `client`.
///
/// {@tool snippet}
///
/// Excerpt from the starwars example using [ResultAccumulator]
///
/// ```dart
/// class ReviewFeed extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Subscription(
///       options: SubscriptionOptions(
///         document: gql(
///           r'''
///             subscription reviewAdded {
///               reviewAdded {
///                 stars, commentary, episode
///               }
///             }
///           ''',
///         ),
///       ),
///       builder: (result) {
///         if (result.hasException) {
///           return Text(result.exception.toString());
///         }
///
///         if (result.isLoading) {
///           return Center(
///             child: const CircularProgressIndicator(),
///           );
///         }
///         return ResultAccumulator.appendUniqueEntries(
///           latest: result.data,
///           builder: (context, {results}) => DisplayReviews(
///             reviews: results.reversed.toList(),
///           ),
///         );
///       },
///     );
///   }
/// }
/// ```
/// {@end-tool}
class Subscription<TParsed> extends StatefulWidget {
  const Subscription({
    required this.options,
    required this.builder,
    this.onSubscriptionResult,
    Key? key,
  }) : super(key: key);

  final SubscriptionOptions<TParsed> options;
  final SubscriptionBuilder<TParsed> builder;
  final OnSubscriptionResult<TParsed>? onSubscriptionResult;

  @override
  _SubscriptionState<TParsed> createState() => _SubscriptionState();
}

class _SubscriptionState<TParsed> extends State<Subscription<TParsed>> {
  Stream<QueryResult<TParsed>>? stream;
  GraphQLClient? client;

  ConnectivityResult? _currentConnectivityResult;
  StreamSubscription<ConnectivityResult>? _networkSubscription;

  void _initSubscription() {
    stream = client!.subscribe(widget.options);

    if (widget.onSubscriptionResult != null) {
      stream = stream!.map((result) {
        widget.onSubscriptionResult!(result, client);
        return result;
      });
    }
  }

  @override
  void initState() {
    _networkSubscription =
        Connectivity().onConnectivityChanged.listen(_onNetworkChange);

    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final GraphQLClient newClient = GraphQLProvider.of(context).value;
    if (client != newClient) {
      client = newClient;
      _initSubscription();
    }
  }

  @override
  void didUpdateWidget(Subscription<TParsed> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.options.equal(oldWidget.options)) {
      _initSubscription();
    }
  }

  @override
  void dispose() {
    _networkSubscription?.cancel();
    super.dispose();
  }

  Future _onNetworkChange(ConnectivityResult result) async {
    //if from offline to online
    if (_currentConnectivityResult == ConnectivityResult.none &&
        (result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi)) {
      _currentConnectivityResult = result;

      // android connectivitystate cannot be trusted
      // validate with nslookup
      if (Platform.isAndroid) {
        try {
          final nsLookupResult = await InternetAddress.lookup('google.com');
          if (nsLookupResult.isNotEmpty &&
              nsLookupResult[0].rawAddress.isNotEmpty) {
            _initSubscription();
          }
          // on exception -> no real connection, set current state to none
        } on SocketException catch (_) {
          _currentConnectivityResult = ConnectivityResult.none;
        }
      } else {
        _initSubscription();
      }
    } else {
      _currentConnectivityResult = result;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QueryResult<TParsed>>(
      initialData: widget.options.optimisticResult != null
          ? QueryResult.optimistic(
              data: widget.options.optimisticResult as Map<String, dynamic>?,
              parserFn: widget.options.parserFn,
            )
          : QueryResult.loading(parserFn: widget.options.parserFn),
      stream: stream,
      builder: (
        BuildContext buildContext,
        AsyncSnapshot<QueryResult<TParsed>> snapshot,
      ) {
        return widget.builder(snapshot.data!);
      },
    );
  }
}
