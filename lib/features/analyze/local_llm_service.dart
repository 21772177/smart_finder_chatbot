import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LocalLLMStatus { unloaded, downloading, ready, error }

class RecommendedModel {
  final String name;
  final String url;
  final String description;
  final int sizeMb;

  const RecommendedModel({
    required this.name,
    required this.url,
    required this.description,
    required this.sizeMb,
  });
}

class LocalLLMService {
  static const _channel = MethodChannel('com.secondbrain/llm');

  String? _modelName;
  LocalLLMStatus _status = LocalLLMStatus.unloaded;
  String? _error;

  LocalLLMStatus get status => _status;
  String? get modelName => _modelName;
  String? get error => _error;
  bool get isReady => _status == LocalLLMStatus.ready;

  static const recommendedModels = [
    RecommendedModel(
      name: 'Phi-2 (GGUF Q4_K_M)',
      url: 'https://huggingface.co/microsoft/phi-2/resolve/main/phi-2.Q4_K_M.gguf',
      description: '2.7B params, good for Android',
      sizeMb: 1636,
    ),
    RecommendedModel(
      name: 'TinyLlama 1.1B (GGUF Q4_K_M)',
      url: 'https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf',
      description: '1.1B params, fast on mobile',
      sizeMb: 670,
    ),
    RecommendedModel(
      name: 'Gemma 2B (GGUF Q4_K_M)',
      url: 'https://huggingface.co/google/gemma-2b/resolve/main/gemma-2b.Q4_K_M.gguf',
      description: '2B params, balanced quality/speed',
      sizeMb: 1330,
    ),
  ];

  Future<bool> downloadModel(String url, String filename) async {
    _status = LocalLLMStatus.downloading;
    _modelName = filename;

    try {
      final result = await _channel.invokeMethod<bool>('downloadModel', {
        'url': url,
        'filename': filename,
      });
      if (result == true) {
        _status = LocalLLMStatus.ready;
        return true;
      }
      _status = LocalLLMStatus.error;
      _error = 'Download failed';
      return false;
    } on PlatformException catch (e) {
      _status = LocalLLMStatus.error;
      _error = e.message;
      return false;
    }
  }

  Future<bool> loadModel(String path) async {
    _status = LocalLLMStatus.downloading;

    try {
      final result = await _channel.invokeMethod<bool>('loadModel', {
        'path': path,
      });
      if (result == true) {
        _status = LocalLLMStatus.ready;
        return true;
      }
      _status = LocalLLMStatus.error;
      _error = 'Failed to load model';
      return false;
    } on PlatformException catch (e) {
      _status = LocalLLMStatus.error;
      _error = e.message;
      return false;
    }
  }

  Future<String?> generate(String prompt) async {
    if (_status != LocalLLMStatus.ready) return null;

    try {
      return await _channel.invokeMethod<String>('generate', {
        'prompt': prompt,
        'maxTokens': 256,
        'temperature': 0.3,
      });
    } on PlatformException {
      return null;
    }
  }

  Future<void> unloadModel() async {
    try {
      await _channel.invokeMethod('unloadModel');
    } on PlatformException {
      // fall through
    }
    _status = LocalLLMStatus.unloaded;
    _modelName = null;
  }

  Future<String?> _localAnalyze(String text, String prompt) async {
    if (_status != LocalLLMStatus.ready) return null;
    final response = await generate(prompt);
    return response;
  }

  String _buildPrompt(String text, String? mode, String? targetLanguage) {
    switch (mode) {
      case 'explain':
        return 'Explain the following text in simple terms:\n\n$text';
      case 'translate':
        final lang = targetLanguage ?? 'English';
        return 'Translate the following text to $lang:\n\n$text';
      default:
        return 'Summarize the following text concisely:\n\n$text';
    }
  }

  Future<String?> analyze(String text, {String? mode, String? targetLanguage}) async {
    final prompt = _buildPrompt(text, mode, targetLanguage);
    return _localAnalyze(text, prompt);
  }
}

final localLlmServiceProvider = Provider<LocalLLMService>((ref) {
  return LocalLLMService();
});
