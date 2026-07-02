class AnalysisResult {
  final String summary;
  final List<String> keywords;
  final int wordCount;
  final int sentenceCount;

  AnalysisResult({
    required this.summary,
    required this.keywords,
    required this.wordCount,
    required this.sentenceCount,
  });
}

class AnalysisService {
  AnalysisResult analyze(String text) {
    if (text.trim().isEmpty) {
      return AnalysisResult(
        summary: '',
        keywords: [],
        wordCount: 0,
        sentenceCount: 0,
      );
    }

    final sentences = _splitSentences(text);
    final words = _splitWords(text);
    final wordCount = words.length;
    final sentenceCount = sentences.length;

    final wordFreq = _wordFrequency(words);
    final keywords = _extractKeywords(wordFreq);

    final summary = _generateSummary(sentences, wordFreq);

    return AnalysisResult(
      summary: summary,
      keywords: keywords,
      wordCount: wordCount,
      sentenceCount: sentenceCount,
    );
  }

  List<String> _splitSentences(String text) {
    final result = <String>[];
    final sentences = text.split(RegExp(r'[.!?\n]+'));
    for (final s in sentences) {
      final trimmed = s.trim();
      if (trimmed.isNotEmpty && trimmed.length > 10) {
        result.add(trimmed);
      }
    }
    return result;
  }

  List<String> _splitWords(String text) {
    return text.toLowerCase()
        .split(RegExp(r'\W+'))
        .where((w) => w.length > 2)
        .toList();
  }

  Map<String, int> _wordFrequency(List<String> words) {
    final freq = <String, int>{};
    for (final w in words) {
      freq[w] = (freq[w] ?? 0) + 1;
    }
    return freq;
  }

  List<String> _extractKeywords(Map<String, int> wordFreq) {
    final stopWords = {
      'the', 'and', 'for', 'are', 'but', 'not', 'you', 'all',
      'can', 'had', 'her', 'was', 'one', 'our', 'out', 'has',
      'have', 'been', 'some', 'them', 'than', 'that', 'this',
      'very', 'just', 'with', 'from', 'they', 'what', 'when',
      'where', 'which', 'will', 'your', 'about', 'into', 'over',
      'also', 'its', 'then', 'these', 'those',
    };

    final sorted = wordFreq.entries
        .where((e) => !stopWords.contains(e.key))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(10).map((e) => e.key).toList();
  }

  String _generateSummary(List<String> sentences, Map<String, int> wordFreq) {
    if (sentences.isEmpty) return '';

    final scored = sentences.map((s) {
      final words = _splitWords(s);
      double score = 0;
      for (final w in words) {
        score += (wordFreq[w] ?? 0);
      }
      score = words.isEmpty ? 0 : score / words.length;
      return MapEntry(s, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));

    final topN = scored.length < 3 ? scored.length : 3;
    return '${scored.take(topN).map((e) => e.key).join('. ')}.';
  }
}
