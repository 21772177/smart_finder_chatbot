import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/memory/vector_index.dart';

void main() {
  group('VectorIndex', () {
    late VectorIndex index;

    setUp(() {
      index = VectorIndex(4);
    });

    test('add increases size', () {
      index.add('a', Float32List.fromList([1, 0, 0, 0]));
      expect(index.size, 1);
    });

    test('search returns nearest neighbor', () {
      index.add('a', Float32List.fromList([1, 0, 0, 0]));
      index.add('b', Float32List.fromList([0, 1, 0, 0]));

      final results = index.search(Float32List.fromList([1, 0, 0, 0]), 1);
      expect(results.length, 1);
      expect(results.first.id, 'a');
    });

    test('search returns k nearest neighbors', () {
      index.add('a', Float32List.fromList([1, 0, 0, 0]));
      index.add('b', Float32List.fromList([0.9, 0.1, 0, 0]));
      index.add('c', Float32List.fromList([0, 0, 1, 0]));

      final results = index.search(Float32List.fromList([1, 0, 0, 0]), 2);
      expect(results.length, 2);
      expect(results[0].id, 'a');
      expect(results[1].id, 'b');
    });

    test('remove decreases size', () {
      index.add('a', Float32List.fromList([1, 0, 0, 0]));
      index.add('b', Float32List.fromList([0, 1, 0, 0]));
      index.remove('a');
      expect(index.size, 1);

      final results = index.search(Float32List.fromList([1, 0, 0, 0]), 5);
      expect(results.first.id, 'b');
    });

    test('clear empties index', () {
      index.add('a', Float32List.fromList([1, 0, 0, 0]));
      index.clear();
      expect(index.size, 0);
      expect(index.search(Float32List.fromList([1, 0, 0, 0]), 5), isEmpty);
    });

    test('search with k > size returns all entries', () {
      index.add('a', Float32List.fromList([1, 0, 0, 0]));
      final results = index.search(Float32List.fromList([1, 0, 0, 0]), 100);
      expect(results.length, 1);
    });

    test('throws on wrong vector size', () {
      expect(() => index.add('a', Float32List.fromList([1, 0])), throwsArgumentError);
    });

    test('empty index returns empty results', () {
      final results = index.search(Float32List.fromList([1, 0, 0, 0]), 5);
      expect(results, isEmpty);
    });

    test('rebuild after add maintains correctness', () {
      index.add('a', Float32List.fromList([1, 0, 0, 0]));
      index.add('b', Float32List.fromList([0, 1, 0, 0]));
      index.rebuild();

      final results = index.search(Float32List.fromList([1, 0, 0, 0]), 1);
      expect(results.first.id, 'a');
    });

    test('search distances are sorted ascending', () {
      index.add('a', Float32List.fromList([1, 0, 0, 0]));
      index.add('b', Float32List.fromList([0.5, 0.5, 0, 0]));
      index.add('c', Float32List.fromList([0, 0, 1, 0]));

      final results = index.search(Float32List.fromList([1, 0, 0, 0]), 3);
      for (int i = 1; i < results.length; i++) {
        expect(results[i].distance, greaterThanOrEqualTo(results[i - 1].distance));
      }
    });

    test('remove non-existent entry does not crash', () {
      index.add('a', Float32List.fromList([1, 0, 0, 0]));
      index.remove('z');
      expect(index.size, 1);
    });

    test('KD-tree auto-rebuilds on dirty search', () {
      index.add('a', Float32List.fromList([1, 0, 0, 0]));
      index.add('b', Float32List.fromList([0, 1, 0, 0]));
      // Don't call rebuild() explicitly — search should trigger it
      final results = index.search(Float32List.fromList([1, 0, 0, 0]), 2);
      expect(results.length, 2);
    });

    test('multiple add/remove cycles work correctly', () {
      index.add('a', Float32List.fromList([1, 0, 0, 0]));
      index.add('b', Float32List.fromList([0, 1, 0, 0]));
      index.remove('a');
      index.add('c', Float32List.fromList([0, 0, 1, 0]));
      index.remove('b');
      index.add('d', Float32List.fromList([0, 0, 0, 1]));

      expect(index.size, 2);
      final results = index.search(Float32List.fromList([0, 0, 1, 0]), 2);
      expect(results.first.id, 'c');
    });
  });
}
