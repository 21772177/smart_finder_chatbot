import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LocalLLMStatus { unloaded, downloading, ready, error }

class LocalLLMService {
  static const _channel = MethodChannel('com.secondbrain/llm');

  String? _modelName;
  LocalLLMStatus _status = LocalLLMStatus.unloaded;
  String? _error;

  LocalLLMStatus get status => _status;
  String? get modelName => _modelName;
  String? get error => _error;
  bool get isReady => _status == LocalLLMStatus.ready;

  Stream<double>? get downloadProgress => null;

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

  Future<String?> analyze(String text, {String? mode}) async {
    if (_status != LocalLLMStatus.ready) return null;

    final prompt = mode == 'explain'
        ? 'Explain the following text in simple terms:\n\n$text'
        : 'Summarize the following text concisely:\n\n$text';

    final response = await generate(prompt);
    return response;
  }
}

final localLlmServiceProvider = Provider<LocalLLMService>((ref) {
  return LocalLLMService();
});
