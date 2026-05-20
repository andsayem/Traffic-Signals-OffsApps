import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class AppProvider with ChangeNotifier {
  bool _isDarkTheme = true;
  String _languageCode = 'en';
  bool _isOnboarded = false;

  AppProvider() {
    _loadFromStorage();
  }

  bool get isDarkTheme => _isDarkTheme;
  String get languageCode => _languageCode;
  bool get isOnboarded => _isOnboarded;

  void _loadFromStorage() {
    _isDarkTheme = StorageService.isDarkTheme();
    _languageCode = StorageService.getLanguage();
    _isOnboarded = StorageService.isOnboarded();
    notifyListeners();
  }

  Future<void> setDarkTheme(bool isDark) async {
    _isDarkTheme = isDark;
    await StorageService.setDarkTheme(isDark);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    await setDarkTheme(!_isDarkTheme);
  }

  Future<void> setLanguage(String langCode) async {
    _languageCode = langCode;
    await StorageService.setLanguage(langCode);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _isOnboarded = true;
    await StorageService.setOnboarded(true);
    notifyListeners();
  }

  Future<void> resetProgress() async {
    await StorageService.clearAll();
    _isDarkTheme = true;
    _languageCode = 'en';
    _isOnboarded = false;
    notifyListeners();
  }
}
