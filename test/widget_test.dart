import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/analyze/analysis_service.dart';

void main() {
  test('AnalysisService basic functionality', () {
    final service = AnalysisService();
    const text = 'This is a test sentence. It has multiple words.';
    final result = service.analyze(text);

    expect(result.wordCount, greaterThan(0));
    expect(result.sentenceCount, greaterThan(0));
  });
}
