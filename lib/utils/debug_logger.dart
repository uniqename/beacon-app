import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

class DebugLogger {
  static void log(String tag, String message) {
    if (kDebugMode) {
      developer.log('🔍 [$tag] $message');
    }
  }

  static void error(String tag, String message, [Object? error, StackTrace? stack]) {
    if (kDebugMode) {
      developer.log('❌ [$tag] ERROR: $message');
      if (error != null) developer.log('   Error: $error');
      if (stack != null) developer.log('   Stack: $stack');
    }
  }

  static void success(String tag, String message) {
    if (kDebugMode) {
      developer.log('✅ [$tag] $message');
    }
  }

  static void warning(String tag, String message) {
    if (kDebugMode) {
      developer.log('⚠️  [$tag] $message');
    }
  }
}
