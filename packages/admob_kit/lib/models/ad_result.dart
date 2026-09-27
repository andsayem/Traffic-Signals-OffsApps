/// Outcome of an attempt to show an ad. Every `show*`/`registerAction` call
/// in this library resolves to one of these instead of throwing, so the
/// host app can always continue safely regardless of ad state.
enum AdShowResult {
  /// The ad was displayed.
  shown,

  /// No cached ad is available yet (one has been queued to load).
  notReady,

  /// A previous ad of this type was shown too recently.
  cooldown,

  /// This ad type is disabled via [AdMobSettings].
  disabled,

  /// Another full-screen ad is already on screen.
  alreadyShowing,

  /// [AdManager.registerAction] was called, but the configured action
  /// interval hasn't been reached yet.
  frequencyNotMet,

  /// AdMob is not supported on the current platform (e.g. web, desktop).
  unsupportedPlatform,

  /// Ads are currently suppressed via `AdManager.suppressAdsFor`/
  /// `suppressAdsUntil` (e.g. a "remove ads" reward window).
  suppressed,

  /// The SDK reported a failure while showing the ad.
  error,
}

/// Human-readable descriptions, mainly useful for debug UI/logging.
extension AdShowResultDescription on AdShowResult {
  bool get isShown => this == AdShowResult.shown;

  String get description {
    switch (this) {
      case AdShowResult.shown:
        return 'Ad shown successfully';
      case AdShowResult.notReady:
        return 'Ad is not loaded yet';
      case AdShowResult.cooldown:
        return 'Ad is in cooldown period';
      case AdShowResult.disabled:
        return 'Ad type is disabled in settings';
      case AdShowResult.alreadyShowing:
        return 'Another full-screen ad is already showing';
      case AdShowResult.frequencyNotMet:
        return 'Action frequency threshold not reached yet';
      case AdShowResult.unsupportedPlatform:
        return 'AdMob is not supported on this platform';
      case AdShowResult.suppressed:
        return 'Ads are currently suppressed';
      case AdShowResult.error:
        return 'An error occurred while showing the ad';
    }
  }
}
