import 'package:flutter/foundation.dart';

class Logger {
  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('DEBUG: $tagPrefix$message');
    }
  }

  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('INFO: $tagPrefix$message');
    }
  }

  static void error(String message, [String? tag, Object? error]) {
    if (kDebugMode) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      final errorSuffix = error != null ? ' - Error: $error' : '';
      debugPrint('ERROR: $tagPrefix$message$errorSuffix');
    }
  }

  static void warning(String message, [String? tag]) {
    if (kDebugMode) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('WARNING: $tagPrefix$message');
    }
  }
}
