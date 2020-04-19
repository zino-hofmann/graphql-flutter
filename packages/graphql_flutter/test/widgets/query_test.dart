import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:graphql_flutter/src/widgets/query.dart';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';

class MockHttpClient extends Mock implements Client {}

final query = gql("""
  query Foo {
    foo
  }
""");

class Page extends StatefulWidget {
  final Map<String, dynamic> variables;
  final FetchPolicy fetchPolicy;
  final ErrorPolicy errorPolicy;

  Page({
    Key key,
    this.variables,
    this.fetchPolicy,
    this.errorPolicy,
  }): super(key: key);

  @override
  State<StatefulWidget> createState() => PageState();
}

class PageState extends State<Page> {
  Map<String, dynamic> variables;
  FetchPolicy fetchPolicy;
  ErrorPolicy errorPolicy;

  @override
  void initState() {
    super.initState();
    variables = widget.variables;
    fetchPolicy = widget.fetchPolicy;
    errorPolicy = widget.errorPolicy;
  }

  setVariables(Map<String, dynamic> newVariables) {
    setState(() {
      variables = newVariables;
    });
  }

  setFetchPolicy(FetchPolicy newFetchPolicy) {
    setState(() {
      fetchPolicy = newFetchPolicy;
    });
  }

  setErrorPolicy(ErrorPolicy newErrorPolicy) {
    setState(() {
      errorPolicy = newErrorPolicy;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        documentNode: query,
        variables: variables,
        fetchPolicy: fetchPolicy,
        errorPolicy: errorPolicy,
      ),
      builder: (QueryResult result, {
        Refetch refetch,
        FetchMore fetchMore
      }) => Container(),
    );
  }
}

void main() {
  group('Query', () {
    MockHttpClient mockHttpClient;
    HttpLink httpLink;
    ValueNotifier<GraphQLClient> client;

    setUp(() async {
      mockHttpClient = MockHttpClient();
      httpLink = HttpLink(
        uri: 'https://unused/graphql',
        httpClient: mockHttpClient,
      );
      client = ValueNotifier(
        GraphQLClient(
          cache: InMemoryCache(storagePrefix: 'test'),
          link: httpLink,
        ),
      );
    });

    testWidgets('does not issue network request on same options',
        (WidgetTester tester) async {
      final page = Page(
        variables: {
          'foo': 1,
        },
        fetchPolicy: FetchPolicy.networkOnly,
        errorPolicy: ErrorPolicy.ignore,
      );

      await tester.pumpWidget(GraphQLProvider(
        client: client,
        child: page,
      ));

      verify(mockHttpClient.send(any)).called(1);

      tester.state<PageState>(find.byWidget(page))
        ..setVariables({'foo': 1})
        ..setFetchPolicy(FetchPolicy.networkOnly)
        ..setErrorPolicy(ErrorPolicy.ignore);
      await tester.pump();
      verifyNoMoreInteractions(mockHttpClient);
    });

    testWidgets('does not issue network request when policies stays null',
        (WidgetTester tester) async {
      final page = Page(
        variables: {
          'foo': 1,
        },
      );

      await tester.pumpWidget(GraphQLProvider(
        client: client,
        child: page,
      ));

      verify(mockHttpClient.send(any)).called(1);

      tester.state<PageState>(find.byWidget(page))
        ..setFetchPolicy(null)
        ..setErrorPolicy(null);
      await tester.pump();
      verifyNoMoreInteractions(mockHttpClient);
    });

    testWidgets('issues a new network request when variables change',
        (WidgetTester tester) async {
      final page = Page(
        variables: {
          'foo': 1,
        },
      );

      await tester.pumpWidget(GraphQLProvider(
        client: client,
        child: page,
      ));

      verify(mockHttpClient.send(any)).called(1);

      tester.state<PageState>(find.byWidget(page))
        .setVariables({'foo': 2});
      await tester.pump();
      verify(mockHttpClient.send(any)).called(1);
    });

    testWidgets('issues a new network request when fetch policy changes',
        (WidgetTester tester) async {
      final page = Page(
        fetchPolicy: FetchPolicy.networkOnly,
      );

      await tester.pumpWidget(GraphQLProvider(
        client: client,
        child: page,
      ));

      verify(mockHttpClient.send(any)).called(1);

      tester.state<PageState>(find.byWidget(page))
        .setFetchPolicy(FetchPolicy.cacheFirst);
      await tester.pump();
      verify(mockHttpClient.send(any)).called(1);
    });

    testWidgets('issues a new network request when error policy changes',
        (WidgetTester tester) async {
      final page = Page(
        errorPolicy: ErrorPolicy.all,
      );

      await tester.pumpWidget(GraphQLProvider(
        client: client,
        child: page,
      ));

      verify(mockHttpClient.send(any)).called(1);

      tester.state<PageState>(find.byWidget(page))
        .setErrorPolicy(ErrorPolicy.none);
      await tester.pump();
      verify(mockHttpClient.send(any)).called(1);
    });

    testWidgets('does not issues new network request when policies are effectively unchanged',
        (WidgetTester tester) async {
      final page = Page(
        fetchPolicy: FetchPolicy.cacheAndNetwork,
        errorPolicy: null,
      );

      await tester.pumpWidget(GraphQLProvider(
        client: client,
        child: page,
      ));

      verify(mockHttpClient.send(any)).called(1);

      tester.state<PageState>(find.byWidget(page))
        ..setFetchPolicy(null)
        ..setErrorPolicy(ErrorPolicy.none);
      await tester.pump();
      verifyNoMoreInteractions(mockHttpClient);
    });
  });
}
