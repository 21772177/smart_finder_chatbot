import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../settings/settings_service.dart';
import 'analysis_service.dart';

class CloudAnalysisService {
  GenerativeModel? _model;

  void configure(String apiKey) {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3,
        maxOutputTokens: 512,
      ),
    );
  }

  bool get isConfigured => _model != null;

  Future<AnalysisResult> analyze(String text, {String? mode, String? targetLanguage}) async {
    if (!isConfigured) {
      return _localFallback(text);
    }

    try {
      final prompt = _buildPrompt(text, mode, targetLanguage);

      final response = await _model!.generateContent([Content.text(prompt)]);
      final result = response.text ?? '';

      return AnalysisResult(
        summary: result,
        keywords: _extractKeywords(text),
        wordCount: text.split(RegExp(r'\s+')).length,
        sentenceCount: text.split(RegExp(r'[.!?\n]+')).where((s) => s.trim().isNotEmpty).length,
      );
    } catch (_) {
      return _localFallback(text);
    }
  }

  String _buildPrompt(String text, String? mode, String? targetLanguage) {
    if (mode == 'translate') {
      final lang = targetLanguage ?? 'English';
      return 'Translate the following text into $lang. Preserve the original meaning and tone:\n\n$text';
    }
    if (mode == 'explain') {
      return 'Explain the following text in simple terms. Break down complex concepts:\n\n$text';
    }
    return 'Summarize the following text concisely. Extract key points and main ideas:\n\n$text';
  }

  List<String> _extractKeywords(String text) {
    final stopWords = {
      'the', 'and', 'for', 'are', 'but', 'not', 'you', 'all',
      'can', 'had', 'her', 'was', 'one', 'our', 'out', 'has',
      'have', 'been', 'some', 'them', 'than', 'that', 'this',
      'very', 'just', 'with', 'from', 'they', 'what', 'when',
      'where', 'which', 'will', 'your', 'about', 'into', 'over',
      'also', 'its', 'then', 'these', 'those',
    };

    final words = text.toLowerCase()
        .split(RegExp(r'\W+'))
        .where((w) => w.length > 2 && !stopWords.contains(w))
        .toList();

    final freq = <String, int>{};
    for (final w in words) {
      freq[w] = (freq[w] ?? 0) + 1;
    }

    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(10).map((e) => e.key).toList();
  }

  AnalysisResult _localFallback(String text) {
    final words = text.split(RegExp(r'\s+'));
    final sentences = text.split(RegExp(r'[.!?\n]+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    return AnalysisResult(
      summary: sentences.take(3).join('. '),
      keywords: _extractKeywords(text),
      wordCount: words.length,
      sentenceCount: sentences.length,
    );
  }
}

final cloudAnalysisServiceProvider = Provider<CloudAnalysisService>((ref) {
  final settings = ref.watch(settingsServiceProvider);
  final service = CloudAnalysisService();
  final key = settings.llmApiKey;
  if (key != null && key.isNotEmpty) {
    service.configure(key);
  }
  return service;
});
