import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traffic_signal_symbols/ads/ad_service.dart';
import 'package:traffic_signal_symbols/services/storage_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  test('paywall auto-prompt date round-trips (once-a-day gate)', () async {
    expect(StorageService.getPaywallPromptDate(), isNull);
    await StorageService.setPaywallPromptDate('2026-11-01');
    expect(StorageService.getPaywallPromptDate(), '2026-11-01');
  });

  test('ad breaks are a no-op before the ad SDK is initialized', () async {
    // Must not throw or show anything while consent/SDK start-up is pending.
    AdService.instance.registerBreak();
    await AdService.instance.onboardingAdDone;
    expect(AdService.instance.shouldHideAds, isFalse);
  });
}
