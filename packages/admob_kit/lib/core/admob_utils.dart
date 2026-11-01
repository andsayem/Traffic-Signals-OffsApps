import 'dart:async';

import 'package:flutter/foundation.dart';

/// Platform detection that is safe to call on every Flutter target,
/// including web and desktop - unlike `dart:io`'s `Platform`, reading
/// these getters never throws or fails to compile on an unsupported
/// platform, so this library can be included in a project that also
/// targets web/desktop without breaking its build.
class AdMobUtils {
  AdMobUtils._();

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// AdMob (via `google_mobile_ads`) only supports Android and iOS.
  static bool get isSupportedPlatform => isAndroid || isIOS;

  /// Picks [android] or [ios] based on the current platform. Returns an
  /// empty string on any other platform, or if the platform-appropriate
  /// value is `null` (e.g. an app that only configured Android IDs and
  /// deliberately left [ios] unset).
  static String pick({required String android, String? ios}) {
    if (isAndroid) return android;
    if (isIOS) return ios ?? '';
    return '';
  }
}

/// Prevents more than one full-screen ad (interstitial, rewarded,
/// rewarded interstitial, app open) from being shown at the same time.
///
/// Every full-screen ad manager checks [isShowing] before presenting and
/// calls [markShowing]/[markDismissed] around the presentation, so host
/// apps get this protection for free just by going through `AdManager`.
class FullScreenAdGuard {
  FullScreenAdGuard._();

  static bool _isShowing = false;

  static bool get isShowing => _isShowing;

  static void markShowing() => _isShowing = true;

  static void markDismissed() => _isShowing = false;
}

/// Lets a host app temporarily suppress every ad this library would
/// otherwise show on its own initiative - `AdManager.registerAction()`,
/// `AdManager.showInterstitial()`, `AdManager.showAppOpen()` (including
/// its automatic on-resume trigger), and the `AdBanner`/`AdaptiveBannerAd`
/// widgets all check this.
///
/// This is a generic on/off mechanism only - it has no idea *why* a host
/// app suppresses ads (a rewarded "remove ads for 30 minutes" perk, a
/// premium purchase, anything else is entirely the app's business).
/// `AdManager.showRewarded`/`showRewardedInterstitial` deliberately ignore
/// this, since those are ads the app explicitly asked to show - most
/// often exactly how a user earns a suppression window in the first
/// place.
///
/// Banner and native widgets listen to [AdSuppression.notifier], so they
/// hide and return on their own when a window starts or ends.
class AdSuppression {
  AdSuppression._();

  static final ValueNotifier<bool> notifier = ValueNotifier(false);
  static DateTime? _until;
  static Timer? _timer;
  static bool _permanent = false;

  /// True during a timed window or while a permanent suppression (e.g. a
  /// paid "remove ads" subscription) is on.
  static bool get isActive => _permanent || (_until != null && DateTime.now().isBefore(_until!));

  static bool get isPermanent => _permanent;

  /// Turns ads off (or back on) indefinitely, independent of timed windows.
  static void setPermanent(bool value) {
    _permanent = value;
    notifier.value = isActive;
  }

  static DateTime? get until => _until != null && DateTime.now().isBefore(_until!) ? _until : null;

  static void suppressUntil(DateTime until) {
    _timer?.cancel();
    if (!until.isAfter(DateTime.now())) {
      clear();
      return;
    }
    _until = until;
    notifier.value = true;
    _timer = Timer(until.difference(DateTime.now()), clear);
  }

  static void suppressFor(Duration duration) => suppressUntil(DateTime.now().add(duration));

  /// Ends the timed window; a permanent suppression stays on.
  static void clear() {
    _timer?.cancel();
    _until = null;
    notifier.value = isActive;
  }
}
