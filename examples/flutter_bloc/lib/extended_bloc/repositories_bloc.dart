import 'package:gql/language.dart';
import 'package:graphql/client.dart';
import 'package:graphql_flutter_bloc/graphql_flutter_bloc.dart';

class RepositoriesBloc extends QueryBloc<Map<String, dynamic>> {
  static int defaultLimit = 5;

  RepositoriesBloc({GraphQLClient client, WatchQueryOptions options})
      : super(
          client: client,
          options: options ??
              WatchQueryOptions(
                document: parseString(r'''
                  query ReadRepositories($nRepositories: Int!, $after: String) {
                      viewer {
                        id
                        __typename
                        repositories(first: $nRepositories, after: $after) {
                          pageInfo {
                            endCursor
                            hasNextPage
                          }
                          nodes {
                            __typename
                            id
                            name
                            viewerHasStarred
                          }
                        }
                      }
                    }                
                '''),
                variables: <String, dynamic>{
                  'nRepositories': defaultLimit,
                  'after': null,
                  'affiliations': [
                    'OWNER',
                    'ORGANIZATION_MEMBER',
                    'COLLABORATOR'
                  ],
                  'ownerAffiliations': [
                    'OWNER',
                    'ORGANIZATION_MEMBER',
                    'COLLABORATOR'
                  ]
                },
              ),
        );

  @override
  Map<String, dynamic> parseData(Map<String, dynamic> data) {
    return data;
  }

  @override
  bool shouldFetchMore(int i, int threshold) {
    return state.maybeWhen(
        loaded: (data, result) {
          return data['viewer']['repositories']['nodes'].length %
                      RepositoriesBloc.defaultLimit ==
                  0 &&
              i == data['viewer']['repositories']['nodes'].length - threshold;
        },
        orElse: () => false);
  }

  void fetchMore({String after}) {
    add(QueryEvent.fetchMore(
        options: FetchMoreOptions(
      variables: <String, dynamic>{'nRepositories': 5, 'after': after},
      updateQuery: (dynamic previousResultData, dynamic fetchMoreResultData) {
        final List<dynamic> repos = <dynamic>[
          ...previousResultData['viewer']['repositories']['nodes']
              as List<dynamic>,
          ...fetchMoreResultData['viewer']['repositories']['nodes']
              as List<dynamic>
        ];

        fetchMoreResultData['viewer']['repositories']['nodes'] = repos;

        return fetchMoreResultData;
      },
    )));
  }
}
