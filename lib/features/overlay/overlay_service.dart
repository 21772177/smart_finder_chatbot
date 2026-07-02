import 'package:flutter/services.dart';
import '../../core/constants.dart';

typedef OverlayTapCallback = void Function();
typedef CaptureActionCallback = void Function();

class OverlayService {
  static const _channel = MethodChannel(AppConstants.channelOverlay);
  OverlayTapCallback? onTap;
  CaptureActionCallback? onSaveCapture;
  CaptureActionCallback? onDismissCapture;

  void init() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onOverlayTap':
          onTap?.call();
        case 'onSaveCapture':
          onSaveCapture?.call();
        case 'onDismissCapture':
          onDismissCapture?.call();
      }
      return null;
    });
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
  }

  Future<bool> startOverlay() async {
    try {
      final result = await _channel.invokeMethod<bool>('startOverlay');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> stopOverlay() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopOverlay');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> isOverlayActive() async {
    try {
      final result = await _channel.invokeMethod<bool>('isOverlayActive');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> requestAccessibilityPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestAccessibilityPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> isAccessibilityEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAccessibilityEnabled');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> showResult(String text) async {
    try {
      await _channel.invokeMethod('showResult', {'text': text});
    } on PlatformException {
      // fall through
    }
  }

  Future<void> hideResult() async {
    try {
      await _channel.invokeMethod('hideResult');
    } on PlatformException {
      // fall through
    }
  }
}
