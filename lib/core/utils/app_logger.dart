import 'package:flutter/foundation.dart';

/// Centralized logging for the app. Dev-visible only (debugPrint is a
/// no-op in release builds); used instead of silently swallowing errors.
class AppLogger {
  static void error(String tag, Object error, [StackTrace? stackTrace]) {
    debugPrint('[$tag] ERROR: $error');
    if (stackTrace != null) {
      debugPrint('[$tag] STACK:\n$stackTrace');
    }
  }

  static void info(String tag, String message) {
    debugPrint('[$tag] $message');
  }
}