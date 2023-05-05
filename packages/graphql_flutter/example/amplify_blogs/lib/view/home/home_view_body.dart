import 'package:amplify_blogs/api/query_manager.dart';
import 'package:amplify_blogs/model/Blog.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:logger/logger.dart';

class HomeViewBody extends StatefulWidget {
  final ValueNotifier<GraphQLClient> client;

  const HomeViewBody({Key? key, required this.client}) : super(key: key);

  @override
  State<StatefulWidget> createState() => HomeViewState();
}

class HomeViewState extends State<HomeViewBody> {
  final Logger _logger = Logger();
  List<Blog> _blogs = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(width: 20, height: 90),
        Expanded(child: _buildBodyView(context: context))
      ],
    );
  }

  /// Build the scroll view with all the information
  Widget _buildBodyView({required BuildContext context}) {
    return Column(
      children: [
        Expanded(child: _buildScrollView(context: context)),
        const Flexible(child: Text("Subscription data")),
        Expanded(child: _buildUpdateScrollView(context: context)),
      ],
    );
  }

  Widget _buildScrollView({required BuildContext context}) {
    return Query(
        options: QueryOptions<List<Blog>>(
            fetchPolicy: FetchPolicy.networkOnly,
            variables: const {
              "limit": 5,
            },
            parserFn: (Map<String, dynamic> json) {
              var rawList = List.of(json["listBlogs"]["items"]);
              return rawList
                  .map((jsonChat) => Blog.fromJson(jsonChat))
                  .toList();
            },
            document: gql(QueryManagerApp.listBlogs())),
        builder: (QueryResult result,
            {VoidCallback? refetch, FetchMore? fetchMore}) {
          if (result.hasException) {
            _logger.e(result.exception);
            throw Exception(result.exception);
          }
          if (result.isLoading) {
            _logger.i("Still loading");
            return const Text("Loading log post");
          }
          _logger.d(result.data ?? "Data is undefined");
          _blogs = result.parsedData as List<Blog>;
          return ListView(
            children: _blogs.map((chatData) => Text(chatData.name)).toList(),
          );
        });
  }

  Widget _buildUpdateScrollView({required BuildContext context}) {
    return Subscription(
        options: SubscriptionOptions(
          parserFn: (Map<String, dynamic> json) {
            _logger.d("$json");
            return Blog.fromJson(json["createBlog"]);
          },
          document: gql(QueryManagerApp.subscribeToNewBlog()),
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
          var chat = result.parsedData as Blog;
          setState(() {
            _blogs.add(chat);
          });
          return ResultAccumulator.appendUniqueEntries(
            latest: _blogs,
            builder: (context, {results}) =>
                ListView(children: [Text(chat.name)]),
          );
        });
  }
}
