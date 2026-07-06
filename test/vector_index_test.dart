import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';
import 'package:second_brain/features/memory/vector_index.dart';

void main() {
  group('VectorIndex', () {
    late VectorIndex index;

    setUp(() {
      index = VectorIndex(4);
    });

    test('add and search single vector', () {
      index.add('a', Float32List.fromList([1.0, 0.0, 0.0, 0.0]));
      index.add('b', Float32List.fromList([0.0, 1.0, 0.0, 0.0]));

      final results = index.search(Float32List.fromList([1.0, 0.0, 0.0, 0.0]), 1);
      expect(results.length, equals(1));
      expect(results.first.id, equals('a'));
    });

    test('search returns nearest neighbors', () {
      index.add('a', Float32List.fromList([1.0, 0.0, 0.0, 0.0]));
      index.add('b', Float32List.fromList([0.9, 0.1, 0.0, 0.0]));
      index.add('c', Float32List.fromList([0.0, 0.0, 1.0, 0.0]));

      final results = index.search(Float32List.fromList([1.0, 0.0, 0.0, 0.0]), 2);
      expect(results.length, equals(2));
      expect(results[0].id, equals('a'));
      expect(results[1].id, equals('b'));
    });

    test('remove works', () {
      index.add('a', Float32List.fromList([1.0, 0.0, 0.0, 0.0]));
      index.add('b', Float32List.fromList([0.0, 1.0, 0.0, 0.0]));
      index.remove('a');

      final results = index.search(Float32List.fromList([1.0, 0.0, 0.0, 0.0]), 1);
      expect(results.length, equals(1));
      expect(results.first.id, equals('b'));
    });

    test('clear works', () {
      index.add('a', Float32List.fromList([1.0, 0.0, 0.0, 0.0]));
      index.clear();

      final results = index.search(Float32List.fromList([1.0, 0.0, 0.0, 0.0]), 1);
      expect(results.isEmpty, isTrue);
    });

    test('search with k > size returns all', () {
      index.add('a', Float32List.fromList([1.0, 0.0, 0.0, 0.0]));
      final results = index.search(Float32List.fromList([1.0, 0.0, 0.0, 0.0]), 10);
      expect(results.length, equals(1));
    });

    test('rebuild maintains correctness', () {
      index.add('a', Float32List.fromList([1.0, 0.0, 0.0, 0.0]));
      index.add('b', Float32List.fromList([0.0, 1.0, 0.0, 0.0]));
      index.rebuild();

      final results = index.search(Float32List.fromList([1.0, 0.0, 0.0, 0.0]), 2);
      expect(results.length, equals(2));
    });

    test('throws on wrong vector size', () {
      expect(() => index.add('a', Float32List.fromList([1.0, 0.0])), throwsArgumentError);
    });

    test('empty index returns empty results', () {
      final results = index.search(Float32List.fromList([1.0, 0.0, 0.0, 0.0]), 5);
      expect(results.isEmpty, isTrue);
    });
  });
}