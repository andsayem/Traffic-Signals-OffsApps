/// The kinds of ads this library manages.
enum AdType {
  banner,
  adaptiveBanner,
  interstitial,
  rewarded,
  rewardedInterstitial,
  native,
  appOpen,
}

/// Which widget/sizing strategy [AdBanner]-style widgets should use.
enum AdBannerType {
  /// Fixed 320x50 banner.
  banner,

  /// Full-width, screen-aware anchored adaptive banner.
  adaptive,
}
