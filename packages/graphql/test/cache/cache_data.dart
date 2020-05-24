import 'package:gql_exec/gql_exec.dart';
import 'package:gql/language.dart';
import 'package:graphql/src/utilities/helpers.dart';
import 'package:meta/meta.dart';

const String rawOperationKey = 'rawOperationKey';

class TestCase {
  TestCase({
    @required this.data,
    @required String operation,
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
  List<Map<String, dynamic>> normalizedEntities;
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

final updatedCFragment = parseString(r'''
fragment partialC on C {
  __typename 
  id
  new
  cField
}
''');

final updatedCValue = <String, dynamic>{
  '__typename': 'C',
  'id': 6,
  'new': 'field',
  'cField': 'changed value',
};

final Map updatedCBasicTestData = deeplyMergeLeft([
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

final Map updatedSubsetOperationData = {
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
        'cField': 'changed value',
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
