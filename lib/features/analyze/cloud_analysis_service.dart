import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../settings/settings_service.dart';
import 'analysis_service.dart';

enum LLMProvider { gemini, openai, anthropic }

class CloudAnalysisService {
  GenerativeModel? _geminiModel;
  String? _openaiApiKey;
  String? _anthropicApiKey;
  LLMProvider? _currentProvider;
  String _geminiModelName = 'gemini-2.0-flash';
  String _openaiModelName = 'gpt-4o-mini';
  String _anthropicModelName = 'claude-3-haiku-20240307';

  bool get isConfigured => _geminiModel != null || _openaiApiKey != null || _anthropicApiKey != null;

  void configure(LLMProvider provider, String apiKey, {
    String? geminiModel,
    String? openaiModel,
    String? anthropicModel,
  }) {
    _currentProvider = provider;
    if (geminiModel != null) _geminiModelName = geminiModel;
    if (openaiModel != null) _openaiModelName = openaiModel;
    if (anthropicModel != null) _anthropicModelName = anthropicModel;

    switch (provider) {
      case LLMProvider.gemini:
        _geminiModel = GenerativeModel(
          model: _geminiModelName,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.3,
            maxOutputTokens: 512,
          ),
        );
        _openaiApiKey = null;
        _anthropicApiKey = null;
        break;
      case LLMProvider.openai:
        _openaiApiKey = apiKey;
        _geminiModel = null;
        _anthropicApiKey = null;
        break;
      case LLMProvider.anthropic:
        _anthropicApiKey = apiKey;
        _geminiModel = null;
        _openaiApiKey = null;
        break;
    }
  }

  Future<AnalysisResult> analyze(String text, {String? mode, String? targetLanguage}) async {
    if (!isConfigured) {
      return _localFallback(text);
    }

    try {
      final prompt = _buildPrompt(text, mode, targetLanguage);

      switch (_currentProvider) {
        case LLMProvider.gemini:
          return await _analyzeWithGemini(prompt, text);
        case LLMProvider.openai:
          return await _analyzeWithOpenAI(prompt, text);
        case LLMProvider.anthropic:
          return await _analyzeWithAnthropic(prompt, text);
        default:
          return _localFallback(text);
      }
    } catch (_) {
      return _localFallback(text);
    }
  }

  Future<AnalysisResult> _analyzeWithGemini(String prompt, String text) async {
    final response = await _geminiModel!.generateContent([Content.text(prompt)]);
    final result = response.text ?? '';
    return AnalysisResult(
      summary: result,
      keywords: _extractKeywords(text),
      wordCount: text.split(RegExp(r'\s+')).length,
      sentenceCount: text.split(RegExp(r'[.!?\n]+')).where((s) => s.trim().isNotEmpty).length,
    );
  }

  Future<AnalysisResult> _analyzeWithOpenAI(String prompt, String text) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_openaiApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _openaiModelName,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.3,
        'max_tokens': 512,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI API error: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final result = data['choices'][0]['message']['content'] ?? '';

    return AnalysisResult(
      summary: result,
      keywords: _extractKeywords(text),
      wordCount: text.split(RegExp(r'\s+')).length,
      sentenceCount: text.split(RegExp(r'[.!?\n]+')).where((s) => s.trim().isNotEmpty).length,
    );
  }

  Future<AnalysisResult> _analyzeWithAnthropic(String prompt, String text) async {
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'x-api-key': _anthropicApiKey!,
        'Content-Type': 'application/json',
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _anthropicModelName,
        'max_tokens': 512,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.3,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Anthropic API error: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final result = data['content'][0]['text'] ?? '';

    return AnalysisResult(
      summary: result,
      keywords: _extractKeywords(text),
      wordCount: text.split(RegExp(r'\s+')).length,
      sentenceCount: text.split(RegExp(r'[.!?\n]+')).where((s) => s.trim().isNotEmpty).length,
    );
  }

  String _buildPrompt(String text, String? mode, String? targetLanguage) {
    if (mode == 'translate') {
      final lang = targetLanguage ?? 'English';
      return 'Translate the following text into $lang. Preserve the original meaning and tone:\n\n$text';
    }
    if (mode == 'explain') {
      return 'Explain the following text in simple terms. Break down complex concepts:\n\n$text';
    }
    if (mode == 'takeaways') {
      return 'Extract the key actionable takeaways from the following text. Focus on decisions, next steps, and important facts:\n\n$text';
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
  final provider = settings.llmProvider;
  
  switch (provider) {
    case LLMProvider.gemini:
      final key = settings.geminiApiKey;
      if (key != null && key.isNotEmpty) {
        service.configure(LLMProvider.gemini, key, geminiModel: settings.geminiModel);
      }
      break;
    case LLMProvider.openai:
      final key = settings.openaiApiKey;
      if (key != null && key.isNotEmpty) {
        service.configure(LLMProvider.openai, key, openaiModel: settings.openaiModel);
      }
      break;
    case LLMProvider.anthropic:
      final key = settings.anthropicApiKey;
      if (key != null && key.isNotEmpty) {
        service.configure(LLMProvider.anthropic, key, anthropicModel: settings.anthropicModel);
      }
      break;
  }
  return service;
});