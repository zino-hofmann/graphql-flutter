import 'package:gql/language.dart';
import 'package:graphql/client.dart';
import 'package:test/test.dart';

void main() {
  group('Query result', () {
    test('data parsing should work with null data', () {
      int runTimes = 0;
      final result = QueryResult<String?>(
        options: QueryOptions(
          document: parseString('query { bar }'),
          parserFn: (data) {
            runTimes++;
            return data['bar'] as String?;
          },
        ),
        source: QueryResultSource.network,
        data: null,
      );
      expect(result.parsedData, equals(null));
      expect(runTimes, equals(0));
    });
    test('data parsing should work with data', () {
      int runTimes = 0;
      final bar = "Bar";
      final result = QueryResult<String?>(
        options: QueryOptions(
          document: parseString('query { bar }'),
          parserFn: (data) {
            runTimes++;
            return data['bar'] as String?;
          },
        ),
        source: QueryResultSource.network,
        data: {"bar": bar},
      );
      expect(result.parsedData, equals(bar));
      expect(result.parsedData, equals(bar));
      expect(runTimes, equals(1));
    });
    test('data parsing should work with data', () {
      final bar = "Bar";
      final result = QueryResult<String?>(
        options: QueryOptions(
          document: parseString('query { bar }'),
          parserFn: (data) {
            return data['bar'] as String?;
          },
        ),
        source: QueryResultSource.network,
        data: {"bar": bar},
      );
      expect(result.data, equals({"bar": bar}));
    });
    test('updating data should clear parsed data', () {
      int runTimes = 0;
      final bar = "Bar";
      final result = QueryResult<String?>(
        options: QueryOptions(
          document: parseString('query { bar }'),
          parserFn: (data) {
            runTimes++;
            return data['bar'] as String?;
          },
        ),
        source: QueryResultSource.network,
        data: {"bar": bar},
      );
      expect(result.parsedData, equals(bar));
      expect(runTimes, equals(1));
      result.data = {"bar": bar};
      expect(result.parsedData, equals(bar));
      expect(runTimes, equals(2));
    });
  });
}
