import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Simple structured logger with Crashlytics integration.
/// In release mode, errors are automatically reported to Crashlytics.
class AppLogger {
  AppLogger._();

  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[${tag ?? 'DEBUG'}] $message');
    }
  }

  static void info(String message, {String? tag}) {
    debug(message, tag: tag ?? 'INFO');
  }

  static void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    debug('⚠ $message', tag: tag ?? 'WARN');
    if (error != null) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace ?? StackTrace.current, reason: message);
    }
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    debug('✗ $message', tag: tag ?? 'ERROR');
    if (error != null) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace ?? StackTrace.current, reason: message, fatal: false);
    }
  }
}
