## 1.0.0

Initial release.

- Banner, adaptive banner, interstitial, rewarded, rewarded interstitial,
  native, and app open ad support.
- Central `AdMobConfig` (ad unit IDs) and `AdMobSettings` (behavior)
  configuration.
- `AdManager` facade with availability flags, `registerAction()`
  frequency control, and cooldown handling.
- Automatic caching, retry-with-backoff, and reload-after-show for every
  full-screen ad type.
- Global full-screen ad guard preventing overlapping interstitial /
  rewarded / rewarded interstitial / app open ads.
- `AppOpenAdManager` with built-in `WidgetsBindingObserver` lifecycle
  integration.
- Test-ad mode using Google's official test ad unit IDs, defaulting to
  debug builds only.
- Centralized `AdMobLogger`.
