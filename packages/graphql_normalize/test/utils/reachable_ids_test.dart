import 'dart:convert';

import 'package:graphql_normalize/src/utils/reachable_ids.dart';
import 'package:test/test.dart';

void main() {
  test('Test that no stack overflow occurs for a circular reference ', () {
    final queryMap = jsonDecode('''{
              "__typename":"Query",
              "trainer({'id':'ckhi5hgou5038xppf9phzteph'})":{
                "\$ref":"Trainer:ckhi5hgou5038xppf9phzteph"
              }
            }''') as Map<String, dynamic>;
    final trainerMap = jsonDecode('''{
             "__typename":"Trainer",
             "id":"ckhi5hgou5038xppf9phzteph",
             "name":"Trainer",
             "pokemons":[{"\$ref":"Pokemon:ckhie3ik16650xnpfyvjmb1lq"}]
          }''') as Map<String, dynamic>;
    final pokemonMap = jsonDecode('''{
             "__typename":"Pokemon",
             "id":"ckhie3ik16650xnpfyvjmb1lq",
             "name":"Pikachu",
             "trainer":{"\$ref":"Trainer:ckhi5hgou5038xppf9phzteph"}
          }''') as Map<String, dynamic>;

    reachableIds((dataId) {
      if (dataId == 'Query') return queryMap;
      if (dataId == 'Trainer:ckhi5hgou5038xppf9phzteph') return trainerMap;
      if (dataId == 'Pokemon:ckhie3ik16650xnpfyvjmb1lq') return pokemonMap;
      return null;
    });
  });
}
