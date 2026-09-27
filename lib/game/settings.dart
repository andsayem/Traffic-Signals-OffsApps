import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/strings.dart';

/// User preferences, persisted with SharedPreferences.
class AppSettings extends ChangeNotifier {
  static const _langKey = 'app_language';
  static const _hapticsKey = 'haptics';
  static const _labelsKey = 'labels';

  SharedPreferences? _prefs;
  bool haptics = true;

  /// Show part name labels on the 3D vehicle.
  bool labels = true;

  String get lang => appLang.value;

  Future<void> load() async {
    final p = _prefs = await SharedPreferences.getInstance();
    final device = PlatformDispatcher.instance.locale.languageCode;
    appLang.value =
        p.getString(_langKey) ??
        (translations.containsKey(device) ? device : 'en');
    haptics = p.getBool(_hapticsKey) ?? true;
    labels = p.getBool(_labelsKey) ?? true;
    notifyListeners();
  }

  void setLang(String code) {
    appLang.value = code;
    _prefs?.setString(_langKey, code);
    notifyListeners();
  }

  void setHaptics(bool on) {
    haptics = on;
    _prefs?.setBool(_hapticsKey, on);
    notifyListeners();
  }

  void setLabels(bool on) {
    labels = on;
    _prefs?.setBool(_labelsKey, on);
    notifyListeners();
  }
}

final settings = AppSettings();

/// Vibration feedback, respecting the user's setting.
void buzz({bool heavy = false}) {
  if (!settings.haptics) return;
  heavy ? HapticFeedback.heavyImpact() : HapticFeedback.mediumImpact();
}
