import 'package:flutter/foundation.dart';

import '../config/admob_settings.dart';

/// Centralized, prefixed logging for every ad manager. Controlled entirely
/// by [AdMobSettings.enableDebugLogs] / [AdMobSettings.enableLogsInRelease]
/// so a host app can silence this library with one flag.
class AdMobLogger {
  AdMobLogger._();

  static bool get _shouldLog {
    if (!AdMobSettings.enableDebugLogs) return false;
    if (kReleaseMode && !AdMobSettings.enableLogsInRelease) return false;
    return true;
  }

  static void log(String message) {
    if (!_shouldLog) return;
    debugPrint('[AdMob] $message');
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (!_shouldLog) return;
    final suffix = error != null ? ' | $error' : '';
    debugPrint('[AdMob][ERROR] $message$suffix');
  }
}
