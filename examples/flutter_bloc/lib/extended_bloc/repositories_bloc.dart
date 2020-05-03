import 'package:gql/language.dart';
import 'package:graphql/client.dart';

import 'package:graphql_flutter_bloc_example/extended_bloc/graphql/bloc.dart';
import 'package:graphql_flutter_bloc_example/extended_bloc/graphql/event.dart';

class RepositoriesBloc extends GraphqlBloc<Map<String, dynamic>> {
  RepositoriesBloc({GraphQLClient client, WatchQueryOptions options})
      : super(
          client: client,
          options: options ??
              WatchQueryOptions(
                documentNode: parseString(r'''
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
                  'nRepositories': 5,
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

  void fetchMore({String after}) {
    add(GraphqlFetchMoreEvent(
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
