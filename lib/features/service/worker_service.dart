import 'package:flutter/services.dart';

class WorkerService {
  static const _channel = MethodChannel('com.secondbrain/worker');

  Future<void> scheduleCleanup() async {
    await _channel.invokeMethod('scheduleCleanup');
  }
}
