import 'package:flutter/services.dart';
import '../../core/constants.dart';

class ScreenCaptureResult {
  final String? imagePath;
  final String? error;

  const ScreenCaptureResult({this.imagePath, this.error});

  bool get isSuccess => imagePath != null && error == null;
}

class ScreenCaptureService {
  static const _channel = MethodChannel(AppConstants.channelCapture);

  Future<ScreenCaptureResult> captureCurrentScreen() async {
    try {
      final result = await _channel.invokeMethod<String>('captureScreen');
      if (result != null && result.isNotEmpty) {
        return ScreenCaptureResult(imagePath: result);
      }
      return const ScreenCaptureResult(error: 'Capture returned empty result');
    } on PlatformException catch (e) {
      return ScreenCaptureResult(error: e.message ?? 'Capture failed');
    }
  }

  Future<bool> requestMediaProjectionPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestMediaProjection');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> hasMediaProjectionPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasMediaProjectionPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
}
