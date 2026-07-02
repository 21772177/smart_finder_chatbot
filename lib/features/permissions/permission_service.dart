import 'package:flutter/services.dart';

class PermissionService {
  static const _channel = MethodChannel('com.secondbrain/permissions');

  Future<Map<String, bool>> checkAll() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('checkAll');
    if (result == null) return {};
    return result.map((k, v) => MapEntry(k.toString(), v as bool));
  }

  Future<void> openOverlaySettings() async {
    await _channel.invokeMethod('openOverlaySettings');
  }

  Future<void> openAccessibilitySettings() async {
    await _channel.invokeMethod('openAccessibilitySettings');
  }

  Future<void> openNotificationSettings() async {
    await _channel.invokeMethod('openNotificationSettings');
  }

  Future<void> openAppSettings() async {
    await _channel.invokeMethod('openAppSettings');
  }
}
