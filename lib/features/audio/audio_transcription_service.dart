import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AudioTranscriptionService {
  static const _channel = MethodChannel('com.secondbrain/audio');

  bool _isListening = false;
  String? _lastError;

  bool get isListening => _isListening;
  String? get lastError => _lastError;

  Future<String?> startListening() async {
    _isListening = true;
    _lastError = null;

    try {
      final result = await _channel.invokeMethod<String>('startTranscription');
      _isListening = false;
      return result;
    } on PlatformException catch (e) {
      _isListening = false;
      _lastError = e.message;
      return null;
    }
  }

  Future<void> stopListening() async {
    try {
      await _channel.invokeMethod('stopTranscription');
    } on PlatformException {
      // fall through
    }
    _isListening = false;
  }

  Future<bool> checkPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkAudioPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> requestPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestAudioPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
}

final audioTranscriptionServiceProvider = Provider<AudioTranscriptionService>((ref) {
  return AudioTranscriptionService();
});
