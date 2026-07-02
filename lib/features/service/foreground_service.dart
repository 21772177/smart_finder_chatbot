import 'package:flutter/services.dart';

class ForegroundServiceController {
  static const _channel = MethodChannel('com.secondbrain/foreground_service');

  Future<bool> start() async {
    try {
      await _channel.invokeMethod('startService');
      return true;
    } on Exception {
      return false;
    }
  }

  Future<void> stop() async {
    await _channel.invokeMethod('stopService');
  }
}
