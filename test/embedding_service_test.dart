import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/memory/embedding_service.dart';

void main() {
  group('EmbeddingService', () {
    late EmbeddingService service;

    setUp(() {
      service = EmbeddingService();
    });

    test('embed returns vector of correct dimension', () {
      const text = 'test text for embedding';
      final vector = service.embed(text);

      expect(vector.length, equals(256));
    });

    test('embed returns zeros for empty string', () {
      final vector = service.embed('');

      expect(vector, everyElement(equals(0.0)));
    });

    test('embed produces deterministic output for same input', () {
      const text = 'consistent input';
      final v1 = service.embed(text);
      final v2 = service.embed(text);

      expect(v1, equals(v2));
    });

    test('jsonToVector and vectorToJson are inverses', () {
      const text = 'round trip test';
      final vector = service.embed(text);
      final json = service.vectorToJson(vector);
      final restored = service.jsonToVector(json);

      expect(restored.length, equals(vector.length));
      for (int i = 0; i < vector.length; i++) {
        expect(restored[i], closeTo(vector[i], 0.001));
      }
    });

    test('cosineSimilarity returns 1 for identical vectors', () {
      final v = service.embed('same text');
      final similarity = service.cosineSimilarity(v, v);

      expect(similarity, closeTo(1.0, 0.001));
    });

    test('cosineSimilarity returns valid similarity for different texts', () {
      final v1 = service.embed('The quick brown fox jumps over the lazy dog in the forest');
      final v2 = service.embed('Computer programming languages and software development');
      final similarity = service.cosineSimilarity(v1, v2);

      expect(similarity, greaterThanOrEqualTo(-1.0));
      expect(similarity, lessThanOrEqualTo(1.0));
    });

    test('cosineSimilarity handles zero vectors', () {
      final v1 = List<double>.filled(256, 0.0);
      final v2 = List<double>.filled(256, 1.0);
      final similarity = service.cosineSimilarity(v1, v2);

      expect(similarity, equals(0.0));
    });
  });
}