import 'package:test/test.dart';
import 'package:gql/language.dart';

import 'package:graphql_normalize/normalize.dart';
import '../shared_data.dart';

void main() {
  group('FieldFunctionOptions', () {
    final query = parseString('''
      query TestQuery {
        posts {
          id
          author {
            id
            name
          }
          title
          comments {
            id
            commenter {
              id
              name
            }
          }
        }
      }
    ''');

    test('helper methods work correctly', () {
      expect(
        denormalizeOperation(
          addTypename: true,
          document: query,
          read: (dataId) => sharedNormalizedMap[dataId],
          typePolicies: {
            'Query': TypePolicy(
              queryType: true,
              fields: {
                'posts': FieldPolicy(
                  read: (existing, options) {
                    expect(
                        options
                            .isReference(existing[0] as Map<String, dynamic>),
                        equals(true));
                    final posts = options.readField(
                      options.field,
                      existing,
                    );
                    expect(
                        options.toReference(posts![0] as Map<String, dynamic>),
                        equals(existing[0]));
                    return posts;
                  },
                )
              },
            ),
          },
        ),
        equals(sharedResponse),
      );
    });
  });
}
