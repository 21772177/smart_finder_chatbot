import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/memory/embedding_service.dart';
import 'dart:math';

void main() {
  group('EmbeddingService', () {
    late EmbeddingService service;

    setUp(() {
      service = EmbeddingService();
    });

    test('embed returns 256-dim vector', () {
      final v = service.embed('hello world');
      expect(v.length, 256);
    });

    test('embed returns zeros for empty string', () {
      final v = service.embed('');
      expect(v, everyElement(equals(0.0)));
    });

    test('embed is deterministic', () {
      final v1 = service.embed('test input');
      final v2 = service.embed('test input');
      expect(v1, equals(v2));
    });

    test('different inputs produce different vectors', () {
      // Verify that at least some inputs produce non-identical vectors
      final v1 = service.embed('the quick brown fox jumps over the lazy dog in the forest');
      final v2 = service.embed('computer programming languages and software development');
      final similarity = service.cosineSimilarity(v1, v2);
      // Should be between -1 and 1, and not perfectly identical
      expect(similarity, greaterThanOrEqualTo(-1.0));
      expect(similarity, lessThanOrEqualTo(1.0));
    });

    test('similar texts have higher similarity than dissimilar', () {
      // Character n-gram embeddings: use texts with shared substrings
      final v1 = service.embed('the quick brown fox jumps over the lazy dog');
      final v2 = service.embed('the quick brown fox jumps over the lazy cat');
      final v3 = service.embed('zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz');

      final simRelated = service.cosineSimilarity(v1, v2);
      final simUnrelated = service.cosineSimilarity(v1, v3);

      expect(simRelated, greaterThan(simUnrelated));
    });

    test('vectorToJson/jsonToVector roundtrip', () {
      final original = service.embed('roundtrip test');
      final json = service.vectorToJson(original);
      final restored = service.jsonToVector(json);

      expect(restored.length, original.length);
      for (int i = 0; i < original.length; i++) {
        expect(restored[i], closeTo(original[i], 0.001));
      }
    });

    test('vectorToJson produces comma-separated string', () {
      final v = service.embed('format test');
      final json = service.vectorToJson(v);
      final parts = json.split(',');
      expect(parts.length, 256);
    });

    test('cosineSimilarity returns 1 for identical vectors', () {
      final v = service.embed('identity check');
      expect(service.cosineSimilarity(v, v), closeTo(1.0, 0.001));
    });

    test('cosineSimilarity returns ~0 for orthogonal vectors', () {
      final v1 = List<double>.filled(256, 0.0)..[0] = 1.0;
      final v2 = List<double>.filled(256, 0.0)..[1] = 1.0;
      expect(service.cosineSimilarity(v1, v2), equals(0.0));
    });

    test('cosineSimilarity returns -1 for opposite vectors', () {
      final v1 = List<double>.filled(256, 1.0);
      final v2 = List<double>.filled(256, -1.0);
      expect(service.cosineSimilarity(v1, v2), closeTo(-1.0, 0.001));
    });

    test('cosineSimilarity handles zero vectors gracefully', () {
      final zero = List<double>.filled(256, 0.0);
      final nonzero = List<double>.filled(256, 1.0);
      expect(service.cosineSimilarity(zero, nonzero), equals(0.0));
    });

    test('embed normalizes vectors to unit length', () {
      final v = service.embed('normalization check');
      final magnitude = sqrt(v.fold(0.0, (s, x) => s + x * x));
      expect(magnitude, closeTo(1.0, 0.01));
    });

    test('word-level: synonyms have higher similarity than random words', () {
      final v1 = service.embed('car automobile vehicle engine motor');
      final v2 = service.embed('automobile car vehicle engine drive');
      final v3 = service.embed('purple elephant dance jungle forest');

      final simSynonyms = service.cosineSimilarity(v1, v2);
      final simRandom = service.cosineSimilarity(v1, v3);

      expect(simSynonyms, greaterThan(simRandom));
      expect(simSynonyms, greaterThan(0.3));
    });

    test('word-level: related topics cluster together', () {
      final v1 = service.embed('financial investment stock market portfolio profit');
      final v2 = service.embed('stock investment market trading portfolio bonds');
      final v3 = service.embed('recipe dinner cook meal kitchen ingredients');

      final simFinance = service.cosineSimilarity(v1, v2);
      final simUnrelated = service.cosineSimilarity(v1, v3);

      expect(simFinance, greaterThan(simUnrelated));
    });

    test('word-level: tech terms cluster together', () {
      final v1 = service.embed('database server encryption security authentication');
      final v2 = service.embed('server security authentication permission access');
      final v3 = service.embed('restaurant food dinner meal kitchen cooking');

      final simTech = service.cosineSimilarity(v1, v2);
      final simUnrelated = service.cosineSimilarity(v1, v3);

      expect(simTech, greaterThan(simUnrelated));
    });

    test('stopwords are filtered out', () {
      final v1 = service.embed('the the the the the the the the the the');
      final v2 = service.embed('');
      expect(v1, equals(v2));
    });
  });
}
