import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:graphql/client.dart';
import 'package:test/test.dart';

void main() {
  group('query options', () {
    group('type getters', () {
      test('on QueryOptions', () {
        final options = QueryOptions(
          document: parseString('query { bar }'),
        );
        expect(options.type, equals(OperationType.query));
        expect(options.isQuery, equals(true));
      });
      test('on MutationOptions', () {
        final options = MutationOptions(
          document: parseString('mutation { bar }'),
        );
        expect(options.type, equals(OperationType.mutation));
        expect(options.isMutation, equals(true));
      });
      test('on SubscriptionOptions', () {
        final options = SubscriptionOptions(
          document: parseString('subscription { bar }'),
        );
        expect(options.type, equals(OperationType.subscription));
        expect(options.isSubscription, equals(true));
      });
    });
    group('gql integration', () {
      test('Options.asRequest', () {
        final options = QueryOptions(
            document: parseString('query { bar }'),
            variables: {
              'foo': {
                'biz': 'bar',
                'bam': [1]
              }
            },
            context: Context.fromList([
              HttpLinkHeaders(headers: {'my': 'header'})
            ]));
        final req = options.asRequest;
        expect(options.document, equals(req.operation.document));
        expect(options.variables, equals(req.variables));
        expect(options.context, equals(req.context));
      });
    });
  });
}
