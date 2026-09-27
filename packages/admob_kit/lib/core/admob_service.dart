import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/admob_settings.dart';
import 'admob_logger.dart';
import 'admob_utils.dart';

/// Bootstraps the Google Mobile Ads SDK.
///
/// Call once, before `runApp` and before touching any other part of this
/// library:
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await AdMobService.initialize();
///   runApp(const MyApp());
/// }
/// ```
class AdMobService {
  AdMobService._();

  static bool _initialized = false;

  /// Whether [initialize] has already run (successfully or not - it never
  /// throws, so this is `true` after the first call either way).
  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (_initialized) {
      AdMobLogger.log('SDK already initialized, skipping');
      return;
    }

    if (!AdMobUtils.isSupportedPlatform) {
      AdMobLogger.log(
        'Unsupported platform ($defaultTargetPlatform); ad requests will '
        'be skipped everywhere in this library',
      );
      _initialized = true;
      return;
    }

    _warnIfMisconfigured();

    try {
      await MobileAds.instance.initialize();

      if (AdMobSettings.testDeviceIds.isNotEmpty) {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(testDeviceIds: AdMobSettings.testDeviceIds),
        );
      }

      AdMobLogger.log('SDK initialized');
    } catch (e, st) {
      // Ad init must never take the whole app down with it.
      AdMobLogger.error('SDK initialization failed', e, st);
    } finally {
      _initialized = true;
    }
  }

  static void _warnIfMisconfigured() {
    if (AdMobSettings.useTestAds && kReleaseMode) {
      AdMobLogger.log(
        'WARNING: AdMobSettings.useTestAds is true in a release build. '
        'Real ads will NOT be served - set it to false before shipping.',
      );
    }
    if (!AdMobSettings.useTestAds && kDebugMode) {
      AdMobLogger.log(
        'WARNING: AdMobSettings.useTestAds is false in a debug build. '
        'Production ad unit IDs will be requested during development.',
      );
    }
  }
}
