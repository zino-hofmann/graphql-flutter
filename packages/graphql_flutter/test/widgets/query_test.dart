import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel, MethodCall;
import 'package:flutter_test/flutter_test.dart';

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';

class MockHttpClient extends Mock implements http.Client {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest? request) =>
      super.noSuchMethod(
        Invocation.method(#send, [request]),
        returnValue: Future.value(
          http.StreamedResponse(
            Stream.fromIterable(const [<int>[]]),
            500,
          ),
        ),
      ) as Future<http.StreamedResponse>;
}

final query = gql("""
  query Foo {
    foo
  }
""");

/// https://flutter.dev/docs/cookbook/persistence/reading-writing-files#testing
Future<void> mockApplicationDocumentsDirectory() async {
// Create a temporary directory.
  final directory = await Directory.systemTemp.createTemp();

  // Mock out the MethodChannel for the path_provider plugin.
  const MethodChannel('plugins.flutter.io/path_provider')
      .setMockMethodCallHandler((MethodCall methodCall) async {
    // If you're getting the apps documents directory, return the path to the
    // temp directory on the test environment instead.
    if (methodCall.method == 'getApplicationDocumentsDirectory') {
      return directory.path;
    }
    return null;
  });
}

class Page extends StatefulWidget {
  final Map<String, dynamic>? variables;
  final FetchPolicy? fetchPolicy;
  final ErrorPolicy? errorPolicy;

  Page({
    Key? key,
    this.variables,
    this.fetchPolicy,
    this.errorPolicy,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => PageState();
}

class PageState extends State<Page> {
  Map<String, dynamic> variables = const {};
  FetchPolicy? fetchPolicy;
  ErrorPolicy? errorPolicy;

  @override
  void initState() {
    super.initState();
    variables = widget.variables ?? const {};
    fetchPolicy = widget.fetchPolicy;
    errorPolicy = widget.errorPolicy;
  }

  setVariables(Map<String, dynamic> newVariables) {
    setState(() {
      variables = newVariables;
    });
  }

  setFetchPolicy(FetchPolicy? newFetchPolicy) {
    setState(() {
      fetchPolicy = newFetchPolicy;
    });
  }

  setErrorPolicy(ErrorPolicy? newErrorPolicy) {
    setState(() {
      errorPolicy = newErrorPolicy;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: query,
        variables: variables,
        fetchPolicy: fetchPolicy,
        errorPolicy: errorPolicy,
      ),
      builder: (QueryResult result, {Refetch? refetch, FetchMore? fetchMore}) =>
          Container(),
    );
  }
}

void main() {
  setUpAll(() async {
    await mockApplicationDocumentsDirectory();
    await initHiveForFlutter();
  });

  group('Query', () {
    late MockHttpClient mockHttpClient;
    HttpLink httpLink;
    ValueNotifier<GraphQLClient>? client;

    setUp(() async {
      mockHttpClient = MockHttpClient();
      httpLink = HttpLink(
        'https://unused/graphql',
        httpClient: mockHttpClient,
      );
      client = ValueNotifier(
        GraphQLClient(
          cache: GraphQLCache(store: await HiveStore.open()),
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

      verify(
        mockHttpClient.send(
          argThat(isA<http.Request>()
              .having((request) => request.method, "method", "POST")
              .having((request) => request.headers, "headers", isNotNull)
              .having((request) => request.body, "body", isNotNull)
              .having(
                (request) => request.url,
                "expected endpoint",
                Uri.parse('https://unused/graphql'),
              )),
        ),
      ).called(1);

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

      verify(
        mockHttpClient.send(
          argThat(isA<http.Request>()
              .having((request) => request.method, "method", "POST")
              .having((request) => request.headers, "headers", isNotNull)
              .having((request) => request.body, "body", isNotNull)
              .having(
                (request) => request.url,
                "expected endpoint",
                Uri.parse('https://unused/graphql'),
              )),
        ),
      ).called(1);

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

      verify(
        mockHttpClient.send(
          argThat(isA<http.Request>()
              .having((request) => request.method, "method", "POST")
              .having((request) => request.headers, "headers", isNotNull)
              .having((request) => request.body, "body", isNotNull)
              .having(
                (request) => request.url,
                "expected endpoint",
                Uri.parse('https://unused/graphql'),
              )),
        ),
      ).called(1);

      tester.state<PageState>(find.byWidget(page)).setVariables({'foo': 2});
      await tester.pump();
      verify(
        mockHttpClient.send(
          argThat(isA<http.Request>()
              .having((request) => request.method, "method", "POST")
              .having((request) => request.headers, "headers", isNotNull)
              .having((request) => request.body, "body", isNotNull)
              .having(
                (request) => request.url,
                "expected endpoint",
                Uri.parse('https://unused/graphql'),
              )),
        ),
      ).called(1);
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

      verify(
        mockHttpClient.send(
          argThat(isA<http.Request>()
              .having((request) => request.method, "method", "POST")
              .having((request) => request.headers, "headers", isNotNull)
              .having((request) => request.body, "body", isNotNull)
              .having(
                (request) => request.url,
                "expected endpoint",
                Uri.parse('https://unused/graphql'),
              )),
        ),
      ).called(1);

      tester
          .state<PageState>(find.byWidget(page))
          .setFetchPolicy(FetchPolicy.cacheFirst);
      await tester.pump();
      verify(
        mockHttpClient.send(
          argThat(isA<http.Request>()
              .having((request) => request.method, "method", "POST")
              .having((request) => request.headers, "headers", isNotNull)
              .having((request) => request.body, "body", isNotNull)
              .having(
                (request) => request.url,
                "expected endpoint",
                Uri.parse('https://unused/graphql'),
              )),
        ),
      ).called(1);
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

      verify(
        mockHttpClient.send(
          argThat(isA<http.Request>()
              .having((request) => request.method, "method", "POST")
              .having((request) => request.headers, "headers", isNotNull)
              .having((request) => request.body, "body", isNotNull)
              .having(
                (request) => request.url,
                "expected endpoint",
                Uri.parse('https://unused/graphql'),
              )),
        ),
      ).called(1);

      tester
          .state<PageState>(find.byWidget(page))
          .setErrorPolicy(ErrorPolicy.none);
      await tester.pump();
      verify(
        mockHttpClient.send(
          argThat(isA<http.Request>()
              .having((request) => request.method, "method", "POST")
              .having((request) => request.headers, "headers", isNotNull)
              .having((request) => request.body, "body", isNotNull)
              .having(
                (request) => request.url,
                "expected endpoint",
                Uri.parse('https://unused/graphql'),
              )),
        ),
      ).called(1);
    });

    testWidgets(
        'does not issues new network request when policies are effectively unchanged',
        (WidgetTester tester) async {
      final page = Page(
        fetchPolicy: FetchPolicy.cacheAndNetwork,
        errorPolicy: null,
      );

      await tester.pumpWidget(GraphQLProvider(
        client: client,
        child: page,
      ));

      verify(
        mockHttpClient.send(
          argThat(isA<http.Request>()
              .having((request) => request.method, "method", "POST")
              .having((request) => request.headers, "headers", isNotNull)
              .having((request) => request.body, "body", isNotNull)
              .having(
                (request) => request.url,
                "expected endpoint",
                Uri.parse('https://unused/graphql'),
              )),
        ),
      ).called(1);

      tester.state<PageState>(find.byWidget(page))
        ..setFetchPolicy(null)
        ..setErrorPolicy(ErrorPolicy.none);
      await tester.pump();
      verifyNoMoreInteractions(mockHttpClient);
    });
  });
}
