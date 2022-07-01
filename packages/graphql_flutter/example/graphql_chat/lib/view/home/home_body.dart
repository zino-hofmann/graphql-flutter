<<<<<<< HEAD
=======
import 'dart:convert';

>>>>>>> feat(graphql_flutter): add graphql flutter example
import 'package:flutter/cupertino.dart';
import 'package:graphql_chat/api/query.dart';
import 'package:graphql_chat/model/chat.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:logger/logger.dart';

class HomeViewBody extends StatelessWidget {
  final Logger _logger = Logger();
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
          parserFn: (Map<String, dynamic> json) {
            var rawList = List.of(json["getChats"]);
            return rawList.map((jsonChat) => Chat.fromJSON(jsonChat)).toList();
          },
        document: gql(Queries.getGetQuery())
    ), builder: (QueryResult result, { VoidCallback? refetch, FetchMore? fetchMore }) {
      if (result.hasException) {
        _logger.e(result.exception);
        throw Exception(result.exception);
      }
      if (result.isLoading) {
        _logger.i("Still loading");
        return const Text("Loading chats");
      }
      _logger.d(result.data ?? "Data is undefined");
      var chats = result.parsedData as List<Chat>;
<<<<<<< HEAD
      return ListView(
        children: chats.map((chatData) => Text(chatData.message)).toList(),
      );
=======
      return Text("Somethings is returned : ${jsonEncode(chats)}");
>>>>>>> feat(graphql_flutter): add graphql flutter example
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