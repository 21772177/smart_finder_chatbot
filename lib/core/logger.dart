import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Simple structured logger with optional Crashlytics integration.
/// In release mode, errors are reported to Crashlytics when Firebase is available.
class AppLogger {
  AppLogger._();

  static bool _firebaseReady = false;

  static void init({required bool firebaseReady}) {
    _firebaseReady = firebaseReady;
  }

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
    debug('\u26a0 $message', tag: tag ?? 'WARN');
    if (error != null && _firebaseReady) {
      try {
        FirebaseCrashlytics.instance.recordError(error, stackTrace ?? StackTrace.current, reason: message);
      } catch (_) {
        // Firebase not available
      }
    }
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    debug('\u2717 $message', tag: tag ?? 'ERROR');
    if (error != null && _firebaseReady) {
      try {
        FirebaseCrashlytics.instance.recordError(error, stackTrace ?? StackTrace.current, reason: message, fatal: false);
      } catch (_) {
        // Firebase not available
      }
    }
  }
}
