import 'package:test/test.dart';
import 'package:graphql/src/websocket/messages.dart'
    show
        // ignore: deprecated_member_use_from_same_package
        LegacyInitOperation,
        InitOperation;

void main() {
  group('LegacyInitOperation', () {
    test('null payload', () {
      // ignore: deprecated_member_use_from_same_package
      final operation = LegacyInitOperation(null);
      expect(operation.toJson(), {'type': 'connection_init'});
    });
    test('simple payload', () {
      // ignore: deprecated_member_use_from_same_package
      final operation = LegacyInitOperation(42);
      expect(operation.toJson(), {'type': 'connection_init', 'payload': '42'});
    });
    test('complex payload', () {
      // ignore: deprecated_member_use_from_same_package
      final operation = LegacyInitOperation({
        'value': 42,
        'nested': {
          'number': [3, 7],
          'string': ['foo', 'bar']
        }
      });
      expect(operation.toJson(), {
        'type': 'connection_init',
        'payload':
            '{"value":42,"nested":{"number":[3,7],"string":["foo","bar"]}}'
      });
    });
  });
  group('InitOperation', () {
    test('null payload', () {
      // ignore: deprecated_member_use_from_same_package
      final operation = InitOperation(null);
      expect(operation.toJson(), {'type': 'connection_init'});
    });
    test('simple payload', () {
      // ignore: deprecated_member_use_from_same_package
      final operation = InitOperation(42);
      expect(operation.toJson(), {'type': 'connection_init', 'payload': 42});
    });
    test('complex payload', () {
      // ignore: deprecated_member_use_from_same_package
      final operation = InitOperation({
        'value': 42,
        'nested': {
          'number': [3, 7],
          'string': ['foo', 'bar']
        }
      });
      expect(operation.toJson(), {
        'type': 'connection_init',
        'payload': {
          'value': 42,
          'nested': {
            'number': [3, 7],
            'string': ['foo', 'bar']
          }
        }
      });
    });
  });
}
