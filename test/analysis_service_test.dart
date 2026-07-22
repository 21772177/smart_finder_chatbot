import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/analyze/analysis_service.dart';

void main() {
  group('AnalysisService', () {
    late AnalysisService service;

    setUp(() {
      service = AnalysisService();
    });

    group('basic analysis', () {
      test('normal text returns non-empty results', () {
        const text = 'Machine learning algorithms process data efficiently. '
            'Neural networks learn patterns from training examples. '
            'Deep learning has transformed computer vision and natural language processing. '
            'These technologies power modern applications across industries.';

        final result = service.analyze(text);

        expect(result.summary, isNotEmpty);
        expect(result.keywords, isNotEmpty);
        expect(result.wordCount, greaterThan(0));
        expect(result.sentenceCount, greaterThan(0));
      });

      test('empty text returns zero counts', () {
        final result = service.analyze('');
        expect(result.summary, isEmpty);
        expect(result.keywords, isEmpty);
        expect(result.wordCount, 0);
        expect(result.sentenceCount, 0);
      });

      test('whitespace-only text returns zero counts', () {
        final result = service.analyze('   \n\t  ');
        expect(result.wordCount, 0);
      });
    });

    group('word counting', () {
      test('counts words correctly', () {
        final result = service.analyze('one two three four five');
        expect(result.wordCount, 5);
      });

      test('filters short words (<=2 chars)', () {
        final result = service.analyze('I am a test');
        // "I" (1), "am" (2), "a" (1) are filtered; "test" (4) remains
        expect(result.wordCount, 1);
      });
    });

    group('sentence counting', () {
      test('counts sentences with . ! ? delimiters', () {
        final result = service.analyze(
          'This is the first sentence of the text. '
          'This is the second sentence here! '
          'Is this the third sentence? '
          'And the fourth sentence too.',
        );
        expect(result.sentenceCount, 4);
      });

      test('filters very short sentences', () {
        // Sentences shorter than 10 chars after trimming are filtered
        final result = service.analyze('Hi. This is a long enough sentence to count.');
        expect(result.sentenceCount, 1);
      });
    });

    group('keyword extraction', () {
      test('extracts frequent meaningful words', () {
        const text = 'python python python java java programming programming code code code';
        final result = service.analyze(text);

        expect(result.keywords, contains('python'));
        expect(result.keywords, contains('code'));
        expect(result.keywords, contains('programming'));
        expect(result.keywords, contains('java'));
      });

      test('filters common stop words', () {
        const base = 'the and for are but not you all can had her was one our out has ';
        final text = base * 20;
        final result = service.analyze(text);

        expect(result.keywords, isNot(contains('the')));
        expect(result.keywords, isNot(contains('and')));
        expect(result.keywords, isNot(contains('for')));
      });

      test('returns at most 10 keywords', () {
        final words = List.generate(20, (i) => 'word$i').join(' ');
        final text = words * 5; // Repeat to boost frequency
        final result = service.analyze(text);
        expect(result.keywords.length, lessThanOrEqualTo(10));
      });
    });

    group('summary generation', () {
      test('summary contains top sentences', () {
        const text = 'Data science involves statistics and programming. '
            'Machine learning is a core part of data science. '
            'Python is widely used for data analysis and visualization. '
            'Cloud computing enables scalable data processing.';

        final result = service.analyze(text);
        expect(result.summary, isNotEmpty);
        expect(result.summary.length, greaterThan(20));
      });

      test('summary ends with period', () {
        const text = 'This is a test sentence that should generate a summary.';
        final result = service.analyze(text);
        expect(result.summary, endsWith('.'));
      });
    });
  });
}
