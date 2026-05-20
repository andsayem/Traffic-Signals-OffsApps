import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static const String _keyTheme = 'is_dark_theme';
  static const String _keyLanguage = 'selected_language';
  static const String _keyFavorites = 'favorite_signs';
  static const String _keyRecentCountries = 'recent_countries';
  static const String _keyOnboarded = 'is_onboarded';

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
    return _prefs?.getBool(_keyTheme) ?? true; // Default to dark theme for premium aesthetic
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

  static Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
