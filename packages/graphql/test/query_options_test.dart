import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:graphql/client.dart';
import 'package:test/test.dart';

void main() {
  group('query options', () {
    group('equality', () {
      test('compares content', () {
        final fn = (_d) => null;
        final t1 = QueryOptions(
          variables: {'foo': 'bar'},
          document: parseString('query { bar }'),
          parserFn: fn,
        );
        final t2 = QueryOptions(
          variables: {'foo': 'bar'},
          document: parseString('query { bar }'),
          parserFn: fn,
        );
        final t3 = QueryOptions(
          document: parseString('query { barz }'),
          parserFn: fn,
        );
        expect(t1, equals(t2));
        expect(t1.hashCode, equals(t2.hashCode));
        expect(t1, isNot(equals(t3)));
        expect(t1.hashCode, isNot(equals(t3.hashCode)));
      });
    });
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

  group('policies', () {
    final policies = Policies(
      fetch: FetchPolicy.cacheFirst,
      error: ErrorPolicy.all,
      cacheReread: CacheRereadPolicy.ignoreAll,
    );

    group('Policies.copyWith', () {
      test('fetch changes only fetch', () {
        final copy = policies.copyWith(fetch: FetchPolicy.networkOnly);
        expect(
          copy,
          equals(Policies(
            fetch: FetchPolicy.networkOnly,
            error: ErrorPolicy.all,
            cacheReread: CacheRereadPolicy.ignoreAll,
          )),
        );
      });

      test('error changes only error', () {
        final copy = policies.copyWith(error: ErrorPolicy.ignore);
        expect(
          copy,
          equals(Policies(
            fetch: FetchPolicy.cacheFirst,
            error: ErrorPolicy.ignore,
            cacheReread: CacheRereadPolicy.ignoreAll,
          )),
        );
      });

      test('no arguments returns an equal copy', () {
        expect(policies.copyWith(), equals(policies));
      });
    });

    group('DefaultPolicies.copyWith', () {
      final slot = {
        'watchQuery': Policies(fetch: FetchPolicy.networkOnly),
        'query': Policies(fetch: FetchPolicy.cacheOnly),
        'watchMutation': Policies(error: ErrorPolicy.all),
        'mutate': Policies(error: ErrorPolicy.ignore),
        'subscribe': Policies(fetch: FetchPolicy.noCache),
      };
      final defaults = DefaultPolicies(
        watchQuery: slot['watchQuery'],
        query: slot['query'],
        watchMutation: slot['watchMutation'],
        mutate: slot['mutate'],
        subscribe: slot['subscribe'],
      );
      final replacement = Policies(
        fetch: FetchPolicy.cacheAndNetwork,
        error: ErrorPolicy.all,
        cacheReread: CacheRereadPolicy.ignoreOptimisitic,
      );

      for (final changed in slot.keys) {
        test('$changed changes only $changed', () {
          final copy = defaults.copyWith(
            watchQuery: changed == 'watchQuery' ? replacement : null,
            query: changed == 'query' ? replacement : null,
            watchMutation: changed == 'watchMutation' ? replacement : null,
            mutate: changed == 'mutate' ? replacement : null,
            subscribe: changed == 'subscribe' ? replacement : null,
          );
          final expected = {
            'watchQuery': defaults.watchQuery,
            'query': defaults.query,
            'watchMutation': defaults.watchMutation,
            'mutate': defaults.mutate,
            'subscribe': defaults.subscribe,
            changed: replacement,
          };
          expect(copy.watchQuery, equals(expected['watchQuery']));
          expect(copy.query, equals(expected['query']));
          expect(copy.watchMutation, equals(expected['watchMutation']));
          expect(copy.mutate, equals(expected['mutate']));
          expect(copy.subscribe, equals(expected['subscribe']));
        });
      }

      test('no arguments returns an equal copy', () {
        expect(defaults.copyWith(), equals(defaults));
      });
    });
  });
}
