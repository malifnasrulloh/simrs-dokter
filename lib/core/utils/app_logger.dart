import 'package:flutter/foundation.dart';

/// Centralized logging for the app. Dev-visible only (debugPrint is a
/// no-op in release builds); used instead of silently swallowing errors.
class AppLogger {
  static void info(String tag, String message) {
    debugPrint('[$tag] INFO: $message');
  }

  static void warn(String tag, String message) {
    debugPrint('[$tag] WARN: $message');
  }

  static void error(String tag, Object error, [StackTrace? stackTrace]) {
    debugPrint('[$tag] ERROR: $error');
    if (stackTrace != null) {
      debugPrint('[$tag] STACK:\n$stackTrace');
    }
  }
}