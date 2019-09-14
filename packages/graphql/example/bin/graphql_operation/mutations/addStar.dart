import 'package:gql/ast.dart';
import 'package:gql/language.dart';

final DocumentNode addStar = parseString(r'''
  mutation AddStar($starrableId: ID!) {
    action: addStar(input: {starrableId: $starrableId}) {
      starrable {
        viewerHasStarred
      }
    }
  }
''');
