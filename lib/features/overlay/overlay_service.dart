import 'package:flutter/services.dart';
import '../../core/constants.dart';

class OverlayService {
  static const _channel = MethodChannel(AppConstants.channelOverlay);

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
}
