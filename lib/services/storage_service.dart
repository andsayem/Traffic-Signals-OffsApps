import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static const String _keyTheme = 'is_dark_theme';
  static const String _keyLanguage = 'selected_language';
  static const String _keyFavorites = 'favorite_signs';
  static const String _keyRecentCountries = 'recent_countries';
  static const String _keyOnboarded = 'is_onboarded';
  static const String _keyIsPro = 'is_pro_subscriber';
  static const String _keyAdFreeUntil = 'ad_free_until_ms';
  static const String _keySelectedCountry = 'selected_country';
  static const String _keyLearnedSigns = 'learned_signs';
  static const String _keyQuizzesDone = 'quizzes_done';
  static const String _keyHomeTourDone = 'home_tour_done';

  // Initialize SharedPreferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Onboarding
  static bool isOnboarded() {
    return _prefs?.getBool(_keyOnboarded) ?? false;
  }

  static Future<void> setOnboarded(bool value) async {
    await _prefs?.setBool(_keyOnboarded, value);
  }

  // Theme Preference
  static bool isDarkTheme() {
    return _prefs?.getBool(_keyTheme) ??
        true; // Default to dark theme for premium aesthetic
  }

  static Future<void> setDarkTheme(bool isDark) async {
    await _prefs?.setBool(_keyTheme, isDark);
  }

  // Language Preference
  static String getLanguage() {
    return _prefs?.getString(_keyLanguage) ?? 'en'; // Default to English
  }

  static Future<void> setLanguage(String langCode) async {
    await _prefs?.setString(_keyLanguage, langCode);
  }

  // Favorites
  static List<String> getFavorites() {
    return _prefs?.getStringList(_keyFavorites) ?? [];
  }

  static Future<void> saveFavorites(List<String> favorites) async {
    await _prefs?.setStringList(_keyFavorites, favorites);
  }

  // Recently Viewed Countries
  static List<String> getRecentCountries() {
    return _prefs?.getStringList(_keyRecentCountries) ?? [];
  }

  static Future<void> addRecentCountry(String countryId) async {
    final list = getRecentCountries();
    list.remove(countryId); // Remove if exists to move to top
    list.insert(0, countryId);
    if (list.length > 5) {
      list.removeLast(); // Limit to 5
    }
    await _prefs?.setStringList(_keyRecentCountries, list);
  }

  // Pro subscription status (mirrors the store's entitlement locally so
  // ads/limits can be gated without an async store check on every screen).
  static bool isPro() {
    return _prefs?.getBool(_keyIsPro) ?? false;
  }

  static Future<void> setPro(bool value) async {
    await _prefs?.setBool(_keyIsPro, value);
  }

  // Learning progress: signs the user has opened at least once.
  static List<String> getLearnedSigns() =>
      _prefs?.getStringList(_keyLearnedSigns) ?? [];

  static Future<void> setLearnedSigns(List<String> ids) async {
    await _prefs?.setStringList(_keyLearnedSigns, ids);
  }

  static int getQuizzesDone() => _prefs?.getInt(_keyQuizzesDone) ?? 0;

  static Future<void> incrementQuizzesDone() async {
    await _prefs?.setInt(_keyQuizzesDone, getQuizzesDone() + 1);
  }

  // First-run guided tour of the Home screen.
  static bool isHomeTourDone() => _prefs?.getBool(_keyHomeTourDone) ?? false;

  static Future<void> setHomeTourDone() async {
    await _prefs?.setBool(_keyHomeTourDone, true);
  }

  // Country the user is learning for (auto-detected, user can change).
  static String? getSelectedCountry() => _prefs?.getString(_keySelectedCountry);

  static Future<void> setSelectedCountry(String id) async {
    await _prefs?.setString(_keySelectedCountry, id);
  }

  // End of the rewarded ad-free window (survives app restarts).
  static DateTime? getAdFreeUntil() {
    final ms = _prefs?.getInt(_keyAdFreeUntil);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<void> setAdFreeUntil(DateTime? until) async {
    if (until == null) {
      await _prefs?.remove(_keyAdFreeUntil);
    } else {
      await _prefs?.setInt(_keyAdFreeUntil, until.millisecondsSinceEpoch);
    }
  }

  static Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
