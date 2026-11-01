import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'admob_logger.dart';
import 'admob_utils.dart';

/// Google UMP consent (GDPR / US state privacy messages set up in AdMob).
///
/// Call [gather] once at startup before any ad request. It shows the
/// consent form only where the user's region requires it and never blocks
/// the app for long: it resolves after the form closes, on any error, or
/// after [timeout].
class AdMobConsent {
  AdMobConsent._();

  static Future<void> gather({Duration timeout = const Duration(seconds: 8)}) async {
    if (!AdMobUtils.isSupportedPlatform) return;
    final done = Completer<void>();
    void finish() {
      if (!done.isCompleted) done.complete();
    }

    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () => ConsentForm.loadAndShowConsentFormIfRequired((error) {
          if (error != null) AdMobLogger.log('Consent form: ${error.message}');
          finish();
        }),
        (error) {
          AdMobLogger.log('Consent info update failed: ${error.message}');
          finish();
        },
      );
    } catch (e) {
      AdMobLogger.log('Consent gathering failed: $e');
      finish();
    }
    await done.future.timeout(timeout, onTimeout: () {});
  }

  /// True when the user's region requires a "Privacy options" entry point
  /// (show a Settings item that calls [showPrivacyOptions]).
  static Future<bool> privacyOptionsRequired() async {
    try {
      return await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      return false;
    }
  }

  /// Re-opens the consent form so the user can change their choice.
  static Future<void> showPrivacyOptions() {
    final done = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((_) {
      if (!done.isCompleted) done.complete();
    });
    return done.future;
  }
}
