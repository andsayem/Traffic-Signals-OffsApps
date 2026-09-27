# admob_kit

A reusable, production-ready AdMob layer for Flutter apps. Configure ad
unit IDs once per app, then drive every ad type through `AdManager` -
loading, caching, retry, cooldown, frequency control, and full-screen-ad
overlap protection are all handled internally.

Supports: Banner, Adaptive Banner, Interstitial, Rewarded, Rewarded
Interstitial, Native, App Open. Android and iOS.

This package lives at `packages/admob_kit` inside this Flutter app as a
local path package - see [Using this in another app](#using-this-in-another-app)
for how to reuse it elsewhere.

---

## 1. Installation

From the host app's `pubspec.yaml`:

```yaml
dependencies:
  admob_kit:
    path: packages/admob_kit
```

Then:

```bash
flutter pub get
```

## 2. Configuration

Almost everything you'll ever touch lives in two files:

- `lib/config/admob_config.dart` - your App IDs and Ad Unit IDs.
- `lib/config/admob_settings.dart` - behavior (on/off switches, frequency,
  cooldown, retry, test mode, logging).

## 3. Android App ID setup

In the host app's `android/app/src/main/AndroidManifest.xml`, inside
`<application>`:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy"/>
```

Use the same value as `AdMobConfig.androidAppId`.

## 4. iOS App ID setup

In the host app's `ios/Runner/Info.plist`:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy</string>
```

Use the same value as `AdMobConfig.iosAppId`. iOS 14+ also requires an
`NSUserTrackingUsageDescription` entry if you use `app_tracking_transparency`
alongside AdMob for ATT - that's outside this package's scope.

## 5. Ad Unit ID configuration

Edit `lib/config/admob_config.dart` and replace every `YOUR_..._ID`
placeholder with the real IDs from your AdMob console:

```dart
class AdMobConfig {
  static const String androidAppId = 'ca-app-pub-XXXX~YYYY';
  static const String iosAppId = 'ca-app-pub-XXXX~ZZZZ';

  static const String androidBannerId = 'ca-app-pub-XXXX/1111';
  static const String iosBannerId = 'ca-app-pub-XXXX/2222';
  // ...interstitial, rewarded, rewardedInterstitial, native, appOpen...
}
```

You never call these constants directly - every manager/widget resolves
IDs through `AdMobConfig.bannerId`, `AdMobConfig.interstitialId`, etc.,
which automatically pick the right platform and substitute test IDs while
`AdMobSettings.useTestAds` is `true`.

## 6. Initialization

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AdMobService.initialize();
  AdManager.preloadAll();      // interstitial, rewarded, rewarded interstitial
  AppOpenAdManager.initialize(); // app open ad + lifecycle observer

  runApp(const MyApp());
}
```

`AdMobService.initialize()` is idempotent, never throws, and is a no-op
on unsupported platforms (web/desktop) so this call is always safe.

## 7. Banner usage

```dart
const AdBanner()
```

Fixed 320x50. Loads on mount, disposes on unmount, retries on failure,
renders nothing if it can't load.

## 8. Adaptive banner usage

```dart
const AdaptiveBannerAd()
```

Full width, AdMob-determined height. **Never wrap it in a fixed-height
box** - let it size itself.

```dart
Column(
  children: [
    Expanded(child: YourContent()),
    const AdaptiveBannerAd(),
  ],
)
```

## 9. Interstitial usage

```dart
final result = await AdManager.showInterstitial();
if (result == AdShowResult.shown) {
  // ad was displayed
}
```

Or, more commonly, let frequency control decide for you - see below.

## 10. Rewarded usage

```dart
final result = await AdManager.showRewarded(
  onReward: () {
    // Only called when Google Mobile Ads reports a valid, earned reward.
    unlockFeature();
  },
);
```

## 11. Rewarded Interstitial usage

```dart
final result = await AdManager.showRewardedInterstitial(
  onReward: () => unlockFeature(),
);
```

## 12. Native usage

```dart
const AdNative()
```

Native ads render through a **native factory you register per platform**
(this is a Google Mobile Ads SDK requirement, not something this package
can avoid). Copy the reference files and follow the steps in
[Native Ad setup](#native-ad-setup) below - the layout lives entirely in
that native file, so redesigning the native ad never touches Dart code.

## 13. App Open usage

```dart
AppOpenAdManager.initialize();
```

Call once in `main()`. From then on, an App Open ad is shown automatically
whenever the app returns to the foreground (subject to cooldown and
availability) - no lifecycle code needed in your app. To show one
manually (e.g. right after your own splash screen instead of waiting for
a resume event):

```dart
await AdManager.showAppOpen();
```

## 14. Frequency settings

```dart
AdMobSettings.interstitialActionInterval = 3; // every 3rd action
```

Call `AdManager.registerAction()` at each point in your app where an
interstitial could reasonably follow (e.g. finishing a level, closing a
tool):

```dart
AdManager.registerAction();
```

```text
Action 1 -> not shown (1/3)
Action 2 -> not shown (2/3)
Action 3 -> interstitial shown (3/3, cooldown allowing)
Action 4 -> not shown (1/3)
Action 5 -> not shown (2/3)
Action 6 -> interstitial shown (3/3)
```

## 15. Cooldown settings

```dart
AdMobSettings.interstitialCooldownSeconds = 30;
AdMobSettings.appOpenCooldownSeconds = 60;
AdMobSettings.appOpenMinBackgroundSeconds = 20;
```

An ad shown within the cooldown window since the last one of the same
type returns `AdShowResult.cooldown` instead of displaying again.
`appOpenMinBackgroundSeconds` is a related but separate guard: an
auto-triggered App Open ad only fires on resume if the app was actually
backgrounded for at least this long, so a permission dialog or a quick
notification peek doesn't burn an impression.

## 16. Test ads

```dart
AdMobSettings.useTestAds = true; // defaults to kDebugMode
```

While `true`, every ad manager requests Google's official test ad unit
IDs instead of your configured production IDs - completely independent
of what's in `AdMobConfig`. It defaults to `kDebugMode` so a debug build
never accidentally serves live ad requests, and `AdMobService.initialize()`
logs a loud warning if it detects `useTestAds: true` in a release build
(or `false` in a debug build), so a misconfiguration doesn't ship
silently.

For testing production IDs on a specific real device without flipping
this globally, add its AdMob test device ID instead:

```dart
AdMobSettings.testDeviceIds = ['33BE2250B43518CCDA7DE426D04EE231'];
```

## 17. Debug logs

```dart
AdMobSettings.enableDebugLogs = true;      // master switch
AdMobSettings.enableLogsInRelease = false; // stay off in release by default
```

Every manager logs through `AdMobLogger`, prefixed `[AdMob]`:

```text
[AdMob] SDK initialized
[AdMob] Banner loading
[AdMob] Banner loaded
[AdMob] Interstitial loading
[AdMob] Interstitial loaded
[AdMob] Interstitial shown
[AdMob] Interstitial dismissed
[AdMob] Reward earned: 1 coins
[AdMob] App Open shown
```

## 18. Existing app migration

You don't need to migrate everything at once. Old direct SDK calls and
`AdManager` calls can coexist while you migrate screen by screen.

**Old interstitial code:**

```dart
InterstitialAd.load(
  adUnitId: '...',
  request: const AdRequest(),
  adLoadCallback: InterstitialAdLoadCallback(
    onAdLoaded: (ad) => _ad = ad,
    onAdFailedToLoad: (e) => debugPrint('failed'),
  ),
);
// ...later...
_ad?.show();
```

**New:**

```dart
AdManager.showInterstitial(); // load/cache/retry/cooldown all handled
```

**Old banner code:**

```dart
final banner = BannerAd(
  adUnitId: '...',
  size: AdSize.banner,
  request: const AdRequest(),
  listener: BannerAdListener(/* ... */),
)..load();
// + manual AdWidget + dispose wiring
```

**New:**

```dart
const AdBanner()
```

**Old App Open code:** manual `WidgetsBindingObserver`, manual
`didChangeAppLifecycleState`, manual cache-expiry checks.

**New:**

```dart
AppOpenAdManager.initialize(); // once, in main()
```

Nothing in this package knows about your app's screens, business logic,
points, or premium features - it only manages ads. Every entry point
(`AdManager.showInterstitial()`, `AdManager.registerAction()`, etc.) is
called *by* your app when *you* decide an ad opportunity exists.

---

## Maximizing CPM

eCPM is mostly set by advertiser demand in the auction, not by app code -
but size, placement, and timing all affect fill rate and the quality
signal AdMob's auction sees, which compounds into real eCPM differences.

**Size.** Prefer `AdaptiveBannerAd` over `AdBanner` wherever you can. An
anchored adaptive banner uses more of the available width at a
height AdMob picks for that width, which both fills more often and pays
better than a fixed 320x50 - this is Google's own stated recommendation,
not just a library default. Reach for full-screen formats
(interstitial, rewarded, rewarded interstitial) at natural break points
too - they consistently out-earn banners per impression. Native ads,
when blended into your content's own visual style, also tend to
out-earn a plain banner in the same spot.

**Location.** Bottom-anchored banners (what this README's examples use)
are the highest-viewability, lowest-accidental-click banner placement -
keep them there rather than mid-content unless you have a specific
in-feed design. For interstitials, only show at a transition the user
already expects (finishing a tool, closing a screen) - `AdManager.
registerAction()` already encodes this. Never place any tappable ad
element close enough to your own buttons/nav that a user could tap it
by mistake - that both violates AdMob policy and generates the kind of
invalid-click signal that gets demand throttled.

**Time.** Two things hurt eCPM/fill more than most people expect:
showing ads too often, and showing them at low-quality moments (a
process AdMob's own systems detect and price down over time).
This library's defaults already encode the safe pattern:

- `AdMobSettings.interstitialActionInterval` (default 3) and
  `interstitialCooldownSeconds` (default 30) keep interstitials tied to
  real user actions with breathing room between them, instead of
  showing on every tap.
- App Open ads only auto-show on a genuine return to the app - the very
  first cold-start resume is skipped (`AppOpenAdManager`'s own splash
  flow handles that), and `AdMobSettings.appOpenMinBackgroundSeconds`
  (default 20) skips resumes that were too brief to be a real "coming
  back" moment (a permission dialog, a quick notification peek), which
  would otherwise burn an impression at ~zero viewability.

Tune these per app based on session length and how many ad
opportunities a session naturally has, but don't zero out the cooldowns
or the min-background-seconds guard - showing too aggressively lowers
average session length, which lowers total impressions per user over
time even if any single session shows more ads.

---

## Native Ad setup

Native ads are rendered by the *platform*, not by Flutter widgets, so
each app must register a small native "factory" once. Reference files are
under `android_integration/` and `ios_integration/` in this package.

### Android

1. Copy `android_integration/native_ad_layout.xml` to
   `android/app/src/main/res/layout/native_ad_layout.xml`.
2. Copy `android_integration/NativeAdFactoryExample.kt` to
   `android/app/src/main/kotlin/<your/package/path>/NativeAdFactoryExample.kt`
   and fix the `package` line.
3. In `MainActivity.kt`, register/unregister the factory as shown in the
   comment at the bottom of that file.
4. Edit `native_ad_layout.xml` (and the view bindings in the `.kt` file if
   you add/remove views) to change the design.

### iOS

1. Copy `ios_integration/NativeAdFactoryExample.swift` to
   `ios/Runner/NativeAdFactoryExample.swift`.
2. In `AppDelegate.swift`, register the factory as shown in the comment
   at the bottom of that file.
3. Edit the view layout inside `createNativeAd` to change the design.

The `factoryId` string used at registration must match
`AdMobConfig.nativeAdFactoryId` (default: `'adFactoryExample'`).

---

## Using this in another app

This package has no dependency on anything outside itself
(`flutter` + `google_mobile_ads` only), so reusing it is just:

1. Copy the whole `packages/admob_kit` folder into the other app's
   repository (e.g. also as `packages/admob_kit`).
2. Add the path dependency to that app's `pubspec.yaml`:
   ```yaml
   dependencies:
     admob_kit:
       path: packages/admob_kit
   ```
3. Edit `lib/config/admob_config.dart` with that app's App IDs / Ad Unit
   IDs.
4. Adjust `lib/config/admob_settings.dart` if that app needs different
   frequency/cooldown/retry defaults.
5. If that app renders native ads, redo the native factory registration
   steps above (native code is inherently per-app).
6. Wire up `AdMobService.initialize()`, `AdManager`, and the widgets as
   described in this README.

Nothing else needs to change - the manager/widget code is identical
across every app.

---

## Availability flags

```dart
AdManager.isInterstitialReady
AdManager.isRewardedReady
AdManager.isRewardedInterstitialReady
AdManager.isAppOpenReady
AdManager.isFullScreenAdShowing
```

Use these to, for example, only enable a "Watch ad" button once
`AdManager.isRewardedReady` is `true`.

## Graceful failure, by design

Every `show*`/`load` method in this package catches its own errors and
resolves to an `AdShowResult` (or simply returns) instead of throwing.
No internet, AdMob outages, no-fill, and initialization failures all
degrade to "ad didn't show" - they never crash or block the host app.
