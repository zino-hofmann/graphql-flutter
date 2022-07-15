import 'dart:io';

import 'package:graphql/client.dart';
import 'package:graphql/src/utilities/helpers.dart';
import 'package:test/test.dart';

void main() {
  group('InMemoryStore', () {
    final data = {
      'id': {'key': 'value'},
      'id2': {'otherKey': false}
    };
    test('basic methods', () {
      final store = InMemoryStore();
      store.put('id', data['id']);
      expect(store.get('id'), equals(data['id']));

      store.delete('id');
      expect(store.data, equals({}));
    });
    test('bulk methods', () {
      final store = InMemoryStore();

      store.putAll(data);

      expect(store.data, equals(data));
      expect(store.toMap(), equals(data));

      store.reset();

      expect(data['id'], notNull); // no mutations
    });
  });

  group('HiveStore', () {
    final data = {
      'id': {'key': 'value'},
      'id2': {'otherKey': false}
    };
    final path = './test/cache/test_hive_boxes/';
    test('basic methods', () async {
      final store =
          await HiveStore.open(boxName: 'basic', path: path + 'basic');
      store.put('id', data['id']);
      expect(store.get('id'), equals(data['id']));

      store.delete('id');
      expect(store.toMap(), equals({}));

      await store.box.deleteFromDisk();
    });
    test('bulk methods', () async {
      final store = await HiveStore.open(boxName: 'bulk', path: path + 'bulk');

      store.putAll(data);
      expect(store.toMap(), equals(data));

      await store.reset();
      expect(store.toMap(), equals({}));

      expect(data['id'], notNull); // no mutations

      await store.box.deleteFromDisk();
    });

    test('box rereferencing', () async {
      final store = await HiveStore.open(path: path);
      store.putAll(data);

      expect(HiveStore().toMap(), equals(data));

      await store.box.deleteFromDisk();
    });
    group("Re-open store works", () {
      test("Can re-open store", () async {
        final box1 = await HiveStore.openBox(
          're-open-store',
          path: path,
        );
        final store = HiveStore(box1);
        store.put("id", {'foo': 'bar'});
        final readData = await store.get("id");
        expect(readData, equals({'foo': 'bar'}));
        expect(readData, isA<Map<String, dynamic>>());
        await box1.close();
        final box2 = await HiveStore.openBox(
          're-open-store',
          path: path,
        );
        final store2 = HiveStore(box2);
        final readData2 = await store2.get('id');
        expect(readData2, equals({'foo': 'bar'}));
        expect(readData2, isA<Map<String, dynamic>>());
      });
      test("Can re-open and read nested data", () async {
        final box1 = await HiveStore.openBox(
          're-open-store',
          path: path,
        );
        final store = HiveStore(box1);
        final data = {
          'foo': 'bar',
          'bob': [
            {'nested': true}
          ]
        };
        store.put("id", data);
        final readData = await store.get("id");
        expect(readData, equals(data));
        expect(readData?['bob'], isA<List<dynamic>>());
        expect(readData?['bob'][0], isA<Map<String, dynamic>>());
        await box1.close();
        final box2 = await HiveStore.openBox(
          're-open-store',
          path: path,
        );
        final store2 = HiveStore(box2);
        final readData2 = await store2.get('id');
        expect(readData2, equals(data));
        expect(readData2, isA<Map<String, dynamic>>());
        expect(readData2?['bob'], isA<List<dynamic>>());
        expect(readData2?['bob'][0], isA<Map<String, dynamic>>());
      });
      test("Can put null", () async {
        final box1 = await HiveStore.openBox(
          'put-null',
          path: path,
        );
        final store = HiveStore(box1);
        store.put("id", {'foo': 'bar'});
        store.put("id", null);
        final readData = await store.get("id");
        expect(readData, equals(null));
        await box1.close();
        final box2 = await HiveStore.openBox(
          'put-null',
          path: path,
        );
        final store2 = HiveStore(box2);
        final readData2 = await store2.get('id');
        expect(readData2, equals(null));
        expect(store2.toMap(), isA<Map<String, Map<String, dynamic>?>>());
        expect(store2.toMap(), equals({'id': null}));
      });
    });

    tearDownAll(() async {
      await Directory(path).delete(recursive: true);
    });
  });
}
