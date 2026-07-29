import 'package:gql_exec/gql_exec.dart';
import 'package:gql/language.dart';
import 'package:graphql/client.dart' show Fragment;
import 'package:graphql/src/utilities/helpers.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

const String rawOperationKey = 'rawOperationKey';

class TestCase {
  TestCase({
    required this.data,
    required String operation,
    Map<String, dynamic> variables = const <String, dynamic>{},
    this.normalizedEntities,
  }) : request = Request(
          operation: Operation(document: parseString(operation)),
          variables: variables,
          context: Context(),
        );

  Request request;

  /// data to write to cache
  Map<String, dynamic> data;

  /// entities to inspect the store for, if any
  List<Map<String, dynamic>>? normalizedEntities;
}

final basicTest = TestCase(
  operation: r'''{
    a {
      __typename
      id
      # union
      list {
        __typename
        value 
        ... on Item { id }
      }
      b {
        __typename
        id
        c {
          __typename
          id,
          cField
        }
        bField { field }
      },
      d {
        id,
        dField {field}
      }
      aField { field }
    }
  }''',
  data: {
    'a': {
      '__typename': 'A',
      'id': 1,
      'list': [
        {'__typename': 'Num', 'value': 1},
        {'__typename': 'Num', 'value': 2},
        {'__typename': 'Num', 'value': 3},
        {'__typename': 'Item', 'id': 4, 'value': 4}
      ],
      'b': {
        '__typename': 'B',
        'id': 5,
        'c': {
          '__typename': 'C',
          'id': 6,
          'cField': 'value',
        },
        'bField': {'field': true}
      },
      'd': {
        'id': 9,
        'dField': {'field': true}
      },
      'aField': {'field': false}
    },
  },
);

/// https://github.com/gql-dart/gql/blob/master/links/gql_http_link/test/multipart_upload_test.dart
final fileVarsTest = TestCase(
  data: {
    "multipleUpload": [
      {
        "id": "r1odc4PAz",
        "filename": "sample_upload.jpg",
        "mimetype": "image/jpeg",
        "path": "./uploads/r1odc4PAz-sample_upload.jpg"
      },
      {
        "id": "5Ea18qlMur",
        "filename": "sample_upload.txt",
        "mimetype": "text/plain",
        "path": "./uploads/5Ea18qlMur-sample_upload.txt"
      }
    ],
  },
  operation: r"""
    mutation($files: [Upload!]!) {
      multipleUpload(files: $files) {
        id
        filename
        mimetype
        path
      }
    }
  """,
  variables: {
    'files': [
      http.MultipartFile.fromBytes(
        "",
        [0, 1, 254, 255],
        filename: "sample_upload.jpg",
        contentType: MediaType("image", "jpeg"),
      ),
      http.MultipartFile.fromString(
        "",
        "just plain text",
        filename: "sample_upload.txt",
        contentType: MediaType("text", "plain"),
      ),
    ],
  },
);

final originalCValue = <String, dynamic>{
  '__typename': 'C',
  'id': 6,
  'cField': 'value',
};
final originalCFragment = Fragment(
  document: parseString(
    r'''
      fragment partialC on C {
        __typename 
        id
        cField
      }
    ''',
  ),
);

final updatedCFragment = Fragment(
  document: parseString(
    r'''
      fragment partialC on C {
        __typename 
        id
        new
        cField
      }
    ''',
  ),
);

final updatedCValue = <String, dynamic>{
  '__typename': 'C',
  'id': 6,
  'new': 'field',
  'cField': 'changed value',
};

final Map<String, dynamic>? updatedCBasicTestData = deeplyMergeLeft([
  basicTest.data,
  {
    'a': {
      'b': {
        'c': {
          '__typename': 'C',
          'id': 6,
          'cField': 'changed value',
        },
      },
    },
  },
]);

final basicTestSubsetAValue = TestCase(
  operation: r'''{
    a {
      __typename
      id
      list {
        __typename
        value 
        ... on Item { id }
        }
      d { id }
    }
  }''',
  data: {
    'a': {
      '__typename': 'A',
      'id': 1,
      'list': [
        {'__typename': 'Num', 'value': 5},
        {'__typename': 'Num', 'value': 6},
        {'__typename': 'Num', 'value': 7},
        {
          '__typename': 'Item',
          'id': 8,
          'value': 8,
        }
      ],
      'd': {
        'id': 10,
      },
    },
  },
);

Map<String, dynamic> getUpdatedSubsetOperationData({
  bool withUpdatedC = false,
}) =>
    {
      'a': {
        '__typename': 'A',
        'id': 1,
        'list': basicTestSubsetAValue.data['a']['list'],
        'b': {
          '__typename': 'B',
          'id': 5,
          'c': {
            '__typename': 'C',
            'id': 6,
            'cField': '${withUpdatedC ? "changed " : ""}value',
          },
          'bField': {'field': true}
        },
        'd': {
          'id': 10,
          'dField': {'field': true}
        },
        'aField': {'field': false}
      },
    };

final cyclicalTest = TestCase(operation: r'''{
    a {
      __typename
      id
      b {
        __typename
        id
        as {
          __typename
          id
        }
      }
    }
  }''', data: {
  'a': {
    '__typename': 'A',
    'id': 1,
    'b': {
      '__typename': 'B',
      'id': 5,
      'as': [
        {
          '__typename': 'A',
          'id': 1,
        },
      ]
    },
  },
}, normalizedEntities: [
  {
    '__typename': 'A',
    'id': 1,
    'b': {r"$ref": 'B:5'}
  },
  {
    '__typename': 'B',
    'id': 5,
    'as': [
      {r"$ref": 'A:1'}
    ],
  },
]);

Map<String, dynamic> get cyclicalObjOperationData {
  Map<String, dynamic> a;
  Map<String, dynamic> b;
  a = {
    '__typename': 'A',
    'id': 1,
  };
  b = {
    '__typename': 'B',
    'id': 5,
    'as': [a]
  };
  a['b'] = b;
  return {'a': a};
}

/// Reproduces https://github.com/zino-hofmann/graphql-flutter/issues/1516
///
/// When a list of objects contains nested objects that share the same
/// `__typename` and `id`, the cache normalizes them to the same cache key.
/// The last write wins, so all entries end up with the last item's field values.
final issue1516SameIdTest = TestCase(
  operation: r'''
    query Bracket($id: ID!, $poolId: String!) {
      bracket(id: $id, poolId: $poolId) {
        __typename
        display_name
        matches {
          __typename
          id
          team1_name
          team2_name
          source {
            __typename
            ref {
              __typename
              id
              name
            }
          }
        }
      }
    }
  ''',
  variables: {'id': 'test123', 'poolId': 'pool456'},
  data: {
    'bracket': {
      '__typename': 'Bracket',
      'display_name': 'Test Bracket',
      'matches': [
        {
          '__typename': 'Match',
          'id': 'match1',
          'team1_name': 'Team A',
          'team2_name': 'Team B',
          'source': {
            '__typename': 'Source',
            'ref': {
              '__typename': 'MatchRef',
              'id': 'ref1',
              'name': 'Winner of Match 10',
            },
          },
        },
        {
          '__typename': 'Match',
          'id': 'match2',
          'team1_name': 'Team C',
          'team2_name': 'Team D',
          'source': {
            '__typename': 'Source',
            'ref': {
              '__typename': 'MatchRef',
              'id': 'ref2',
              'name': 'Winner of Match 11',
            },
          },
        },
        {
          '__typename': 'Match',
          'id': 'match3',
          'team1_name': 'Team E',
          'team2_name': 'Team F',
          'source': {
            '__typename': 'Source',
            'ref': {
              '__typename': 'MatchRef',
              'id': 'ref3',
              'name': 'Winner of Match 12',
            },
          },
        },
        {
          '__typename': 'Match',
          'id': 'match4',
          'team1_name': 'Team G',
          'team2_name': 'Team H',
          'source': {
            '__typename': 'Source',
            'ref': {
              '__typename': 'MatchRef',
              'id': 'ref1',
              'name': 'Winner of Match 10',
            },
          },
        },
      ],
    },
  },
);

/// Same as issue1516SameIdTest but ref objects share the same id with
/// different name values - this is the actual scenario that triggers the bug.
/// When different ref objects have the same __typename + id but different
/// field values, cache normalization causes data corruption.
final issue1516ConflictingRefsTest = TestCase(
  operation: r'''
    query Bracket($id: ID!, $poolId: String!) {
      bracket(id: $id, poolId: $poolId) {
        __typename
        display_name
        matches {
          __typename
          id
          team1_name
          source {
            __typename
            ref {
              __typename
              id
              name
            }
          }
        }
      }
    }
  ''',
  variables: {'id': 'test123', 'poolId': 'pool456'},
  data: {
    'bracket': {
      '__typename': 'Bracket',
      'display_name': 'Test Bracket',
      'matches': [
        {
          '__typename': 'Match',
          'id': 'match1',
          'team1_name': 'Team A',
          'source': {
            '__typename': 'Source',
            'ref': {
              '__typename': 'MatchRef',
              'id': 'shared-ref-1',
              'name': 'First Ref Name',
            },
          },
        },
        {
          '__typename': 'Match',
          'id': 'match2',
          'team1_name': 'Team B',
          'source': {
            '__typename': 'Source',
            'ref': {
              '__typename': 'MatchRef',
              'id': 'shared-ref-1',
              'name': 'Second Ref Name',
            },
          },
        },
        {
          '__typename': 'Match',
          'id': 'match3',
          'team1_name': 'Team C',
          'source': {
            '__typename': 'Source',
            'ref': {
              '__typename': 'MatchRef',
              'id': 'shared-ref-1',
              'name': 'Third Ref Name',
            },
          },
        },
      ],
    },
  },
);

final typelessTest = TestCase(
  operation: r'''{
    a {
      # union
      list {
        #__typename
        value 
        #... on Item { id }
      }
      b {
        id
        c {
          id,
          cField
        }
        bField { field }
      },
      d {
        id,
        dField {field}
      }
      aField { field }
    }
  }''',
  data: {
    'a': {
      'list': [
        {
          //'__typename': 'Num',
          'value': 1,
        },
        {
          //'__typename': 'Num',
          'value': 2,
        },
        {
          //'__typename': 'Num',
          'value': 3,
        },
        {
          //'__typename': 'Item',
          //'id': 4,
          'value': 4,
        }
      ],
      'b': {
        'id': 5,
        'c': {
          'id': 6,
          'cField': 'value',
        },
        'bField': {'field': true}
      },
      'd': {
        'id': 9,
        'dField': {'field': true}
      },
      'aField': {'field': false}
    },
  },
);
