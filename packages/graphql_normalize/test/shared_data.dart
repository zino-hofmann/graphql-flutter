final Map<String, Map<String, dynamic>?> sharedNormalizedMap = {
  'Query': {
    '__typename': 'Query',
    'posts': [
      {'\$ref': 'Post:123'}
    ]
  },
  'Post:123': {
    'id': '123',
    '__typename': 'Post',
    'author': {'\$ref': 'Author:1'},
    'title': 'My awesome blog post',
    'comments': [
      {'\$ref': 'Comment:324'}
    ]
  },
  'Author:1': {
    'id': '1',
    '__typename': 'Author',
    'name': 'Paul',
  },
  'Comment:324': {
    'id': '324',
    '__typename': 'Comment',
    'commenter': {'\$ref': 'Author:2'},
  },
  'Author:2': {
    'id': '2',
    '__typename': 'Author',
    'name': 'Nicole',
  }
};

final Map<String, dynamic> sharedResponse = {
  '__typename': 'Query',
  'posts': [
    {
      'id': '123',
      '__typename': 'Post',
      'author': {
        'id': '1',
        '__typename': 'Author',
        'name': 'Paul',
      },
      'title': 'My awesome blog post',
      'comments': [
        {
          'id': '324',
          '__typename': 'Comment',
          'commenter': {
            'id': '2',
            '__typename': 'Author',
            'name': 'Nicole',
          }
        }
      ]
    }
  ]
};
