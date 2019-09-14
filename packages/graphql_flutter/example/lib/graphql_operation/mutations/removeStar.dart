import 'package:gql/ast.dart';
import 'package:gql/language.dart';

final DocumentNode removeStar = parseString(r'''
  mutation RemoveStar($starrableId: ID!) {
    action: removeStar(input: {starrableId: $starrableId}) {
      starrable {
        viewerHasStarred
      }
    }
  }
''');
