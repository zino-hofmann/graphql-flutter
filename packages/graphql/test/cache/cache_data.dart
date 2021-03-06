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

final Map? updatedCBasicTestData = deeplyMergeLeft([
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

getUpdatedSubsetOperationData({withUpdatedC = false}) => {
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
