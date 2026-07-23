import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

/// Structured logger with Crashlytics integration, log levels, and breadcrumbs.
class AppLogger {
  AppLogger._();

  static bool _firebaseReady = false;
  static LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;

  static void init({required bool firebaseReady}) {
    _firebaseReady = firebaseReady;
  }

  static void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  static bool _shouldLog(LogLevel level) => level.index >= _minLevel.index;

  static void debug(String message, {String? tag}) {
    if (_shouldLog(LogLevel.debug) && kDebugMode) {
      // ignore: avoid_print
      print('[${tag ?? 'DEBUG'}] $message');
    }
  }

  static void info(String message, {String? tag}) {
    if (_shouldLog(LogLevel.info)) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[${tag ?? 'INFO'}] $message');
      }
      if (_firebaseReady) {
        try {
          FirebaseCrashlytics.instance.log('[${tag ?? 'INFO'}] $message');
        } catch (_) {}
      }
    }
  }

  static void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (_shouldLog(LogLevel.warning)) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[${tag ?? 'WARN'}] ⚠ $message');
      }
      if (_firebaseReady) {
        try {
          FirebaseCrashlytics.instance.log('[${tag ?? 'WARN'}] $message');
          if (error != null) {
            FirebaseCrashlytics.instance.recordError(
              error, stackTrace ?? StackTrace.current, reason: message,
            );
          }
        } catch (_) {}
      }
    }
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace, bool fatal = false}) {
    if (_shouldLog(LogLevel.error)) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[${tag ?? 'ERROR'}] ✗ $message');
      }
      if (_firebaseReady) {
        try {
          FirebaseCrashlytics.instance.log('[${tag ?? 'ERROR'}] $message');
          if (error != null) {
            FirebaseCrashlytics.instance.recordError(
              error, stackTrace ?? StackTrace.current,
              reason: message, fatal: fatal,
            );
          } else if (fatal) {
            FirebaseCrashlytics.instance.crash();
          }
        } catch (_) {}
      }
    }
  }

  static void breadcrumb(String message, {String? tag}) {
    if (_firebaseReady) {
      try {
        FirebaseCrashlytics.instance.setCustomKey('last_action', message);
        FirebaseCrashlytics.instance.log('[BC] ${tag ?? ''} $message');
      } catch (_) {}
    }
  }
}
