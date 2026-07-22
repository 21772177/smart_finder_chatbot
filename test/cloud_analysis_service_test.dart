import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/analyze/cloud_analysis_service.dart';

void main() {
  group('CloudAnalysisService', () {
    late CloudAnalysisService service;

    setUp(() {
      service = CloudAnalysisService();
    });

    test('isConfigured is false by default', () {
      expect(service.isConfigured, isFalse);
    });

    test('configure with Gemini sets isConfigured', () {
      service.configure(LLMProvider.gemini, 'test-api-key');
      expect(service.isConfigured, isTrue);
    });

    test('configure with OpenAI sets isConfigured', () {
      service.configure(LLMProvider.openai, 'test-key');
      expect(service.isConfigured, isTrue);
    });

    test('configure with Anthropic sets isConfigured', () {
      service.configure(LLMProvider.anthropic, 'test-key');
      expect(service.isConfigured, isTrue);
    });

    test('analyze falls back to local when not configured', () async {
      final result = await service.analyze('Hello world test text here.');
      expect(result.summary, isNotEmpty);
      expect(result.wordCount, greaterThan(0));
    });

    test('analyze handles all modes without cloud', () async {
      const text = 'Machine learning is a subset of artificial intelligence.';

      final summary = await service.analyze(text, mode: 'summarize');
      final explain = await service.analyze(text, mode: 'explain');
      final translate = await service.analyze(text, mode: 'translate', targetLanguage: 'German');
      final takeaways = await service.analyze(text, mode: 'takeaways');

      expect(summary.summary, isNotEmpty);
      expect(explain.summary, isNotEmpty);
      expect(translate.summary, isNotEmpty);
      expect(takeaways.summary, isNotEmpty);
    });

    test('configure switches provider correctly', () {
      service.configure(LLMProvider.gemini, 'gemini-key');
      expect(service.isConfigured, isTrue);

      service.configure(LLMProvider.openai, 'openai-key');
      expect(service.isConfigured, isTrue);

      service.configure(LLMProvider.anthropic, 'anthropic-key');
      expect(service.isConfigured, isTrue);
    });

    test('analyze with empty text returns valid result', () async {
      final result = await service.analyze('');
      expect(result.wordCount, greaterThanOrEqualTo(0));
    });

    test('local fallback extracts keywords', () async {
      const text = 'python programming language development code software engineering';
      final result = await service.analyze(text);

      expect(result.keywords, isNotEmpty);
      expect(result.keywords.length, lessThanOrEqualTo(10));
    });
  });
}
