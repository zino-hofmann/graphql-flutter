import 'package:flutter/material.dart';
import 'package:graphql_chat/api/query.dart';
import 'package:graphql_chat/model/chat.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:logger/logger.dart';

class HomeViewBody extends StatelessWidget {
  final Logger _logger = Logger();
  List<Chat> _chats = [];

  HomeViewBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(width: 20, height: 90),
        Expanded(child: _buildBodyView(context: context))
      ],
    );
  }

  Widget _buildScrollView({required BuildContext context}) {
    return Query(
        options: QueryOptions<List<Chat>>(
            fetchPolicy: FetchPolicy.networkOnly,
            parserFn: (Map<String, dynamic> json) {
              var rawList = List.of(json["getChats"]);
              return rawList
                  .map((jsonChat) => Chat.fromJSON(jsonChat))
                  .toList();
            },
            document: gql(Queries.getGetQuery())),
        builder: (QueryResult result,
            {VoidCallback? refetch, FetchMore? fetchMore}) {
          if (result.hasException) {
            _logger.e(result.exception);
            throw Exception(result.exception);
          }
          if (result.isLoading) {
            _logger.i("Still loading");
            return const Text("Loading chats");
          }
          _logger.d(result.data ?? "Data is undefined");
          _chats = result.parsedData as List<Chat>;
          return ListView(
            children:
                _chats.map((chatData) => Text(chatData.description)).toList(),
          );
        });
  }

  Widget _buildUpdateScrollView({required BuildContext context}) {
    return Subscription(
        options: SubscriptionOptions(
          parserFn: (Map<String, dynamic> json) {
            return Chat.fromJSON(json["chatCreated"]);
          },
          document: gql(Queries.subscribeToNewChat()),
        ),
        builder: (result) {
          if (result.hasException) {
            _logger.e(result.exception);
            return Text(result.exception.toString());
          }

          if (result.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          // ResultAccumulator is a provided helper widget for collating subscription results.
          _logger.d(result.data ?? "Data is undefined");
          var chat = result.parsedData as Chat;
          return ResultAccumulator.appendUniqueEntries(
            latest: _chats,
            builder: (context, {results}) =>
                ListView(children: [Text(chat.name)]),
          );
        });
  }

  /// Build the scroll view with all the information
  Widget _buildBodyView({required BuildContext context}) {
    return Column(
      children: [
        Expanded(child: _buildScrollView(context: context)),
      ],
    );
  }
}
