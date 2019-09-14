import 'package:gql/ast.dart';
import 'package:gql/language.dart';

final DocumentNode readRepositories = parseString(r'''
  query ReadRepositories($nRepositories: Int!) {
    viewer {
      repositories(last: $nRepositories) {
        nodes {
          __typename
          id
          name
          viewerHasStarred
        }
      }
    }
  }
''');

final DocumentNode testSubscription = parseString(r'''
		subscription test {
	    deviceChanged(id: 2) {
        id
        name
      }
		}
''');
