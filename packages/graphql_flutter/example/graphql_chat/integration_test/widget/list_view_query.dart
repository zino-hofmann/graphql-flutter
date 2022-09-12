/// ListView flutter Widget implementation to display all the information
/// of the chats that are created by by the client chat app.
///
/// author: https://github.com/vincenzopalazzo
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:logger/logger.dart';

import '../model/chat_app_model.dart';

class ListChatQueryView extends StatelessWidget {
  /// N.B: Please to not use this approach in a dev environment but
  /// consider to use code generator or put the query content somewhere else.
  String query = r"""
   query {
        getChats {
          __typename
          id
          description
          name
        }
      }
  """;
  Logger _logger = Logger();
  List<Chat> _chats = [];

  @override
  Widget build(BuildContext context) {
    return Query(
        options: QueryOptions<List<Chat>>(
            fetchPolicy: FetchPolicy.networkOnly,
            parserFn: (Map<String, dynamic> json) {
              var rawList = List.of(json["getChats"] as List<dynamic>);
              return rawList
                  .map((jsonChat) =>
                      Chat.fromJSON(Map.from(jsonChat as Map<String, dynamic>)))
                  .toList();
            },
            document: gql(query)),
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
            children: _chats.map((chatData) => Text(chatData.name)).toList(),
          );
        });
  }
}
