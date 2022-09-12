/// ListView flutter Widget implementation to display all the information
/// of the chats that are created by by the client chat app.
///
/// author: https://github.com/vincenzopalazzo
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:logger/logger.dart';

import '../model/chat_app_model.dart';

class ListChatSubscriptionView extends StatelessWidget {
  /// N.B: Please to not use this approach in a dev environment but
  /// consider to use code generator or put the query content somewhere else.
  String query = r"""
  subscription {
      chatCreated {
        id
        name
        description
      }
    }
  """;
  Logger _logger = Logger();
  List<Chat> _chats = [];

  @override
  Widget build(BuildContext context) {
    return Subscription(
        options: SubscriptionOptions(
          parserFn: (Map<String, dynamic> json) {
            return Chat.fromJSON(json["chatCreated"] as Map<String, dynamic>);
          },
          document: gql(query),
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
}
