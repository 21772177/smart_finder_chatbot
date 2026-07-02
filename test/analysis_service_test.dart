import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/analyze/analysis_service.dart';

void main() {
  group('AnalysisService', () {
    late AnalysisService service;

    setUp(() {
      service = AnalysisService();
    });

    test('analyze returns summary and keywords for normal text', () {
      const text = 'This is a sample text with several words. '
          'It contains multiple sentences. The quick brown fox jumps over the lazy dog. '
          'Another sentence here to make it longer.';

      final result = service.analyze(text);

      expect(result.summary, isNotEmpty);
      expect(result.keywords, isNotEmpty);
      expect(result.wordCount, greaterThan(0));
      expect(result.sentenceCount, greaterThan(0));
    });

    test('analyze handles empty text', () {
      final result = service.analyze('');

      expect(result.summary, isEmpty);
      expect(result.keywords, isEmpty);
      expect(result.wordCount, equals(0));
      expect(result.sentenceCount, equals(0));
    });

    test('analyze handles short text', () {
      final result = service.analyze('Hello world.');

      expect(result.wordCount, greaterThan(0));
      expect(result.sentenceCount, greaterThanOrEqualTo(0));
    });

    test('analyze extracts keywords from repeated words', () {
      const text = 'apple banana apple cherry apple banana date';

      final result = service.analyze(text);

      expect(result.keywords, contains('apple'));
      expect(result.keywords, contains('banana'));
    });

    test('analyze counts sentences correctly', () {
      const text = 'First sentence. Second sentence! Third sentence? Fourth sentence.';

      final result = service.analyze(text);

      expect(result.sentenceCount, equals(4));
    });

    test('analyze filters stop words from keywords', () {
      const base = 'the quick brown fox jumps over the lazy dog ';
      final text = base + base + base + base + base + base + base + base + base + base;

      final result = service.analyze(text);

      expect(result.keywords, isNot(contains('the')));
      expect(result.keywords, isNot(contains('over')));
    });
  });
}