import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/analyze/cloud_analysis_service.dart';

void main() {
  group('CloudAnalysisService', () {
    late CloudAnalysisService service;

    setUp(() {
      service = CloudAnalysisService();
    });

    test('isConfigured returns false without API key', () {
      expect(service.isConfigured, isFalse);
    });

    test('analyze returns local fallback when not configured', () async {
      const text = 'Sample text for analysis. It has multiple sentences. Each one is important.';
      final result = await service.analyze(text);

      expect(result.summary, isNotEmpty);
      expect(result.keywords, isNotEmpty);
      expect(result.wordCount, greaterThan(0));
      expect(result.sentenceCount, greaterThan(0));
    });

    test('analyze handles different modes', () async {
      const text = 'Text to analyze with different modes.';

      final summaryResult = await service.analyze(text, mode: 'summarize');
      final explainResult = await service.analyze(text, mode: 'explain');
      final translateResult = await service.analyze(text, mode: 'translate', targetLanguage: 'French');

      expect(summaryResult.summary, isNotEmpty);
      expect(explainResult.summary, isNotEmpty);
      expect(translateResult.summary, isNotEmpty);
    });
  });
}