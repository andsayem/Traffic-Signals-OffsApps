import 'package:flutter/material.dart';
import '../data/local_json_data.dart';
import '../models/country_model.dart';
import '../models/traffic_sign_model.dart';
import '../models/traffic_tip_model.dart';
import '../services/storage_service.dart';

class TrafficDataProvider with ChangeNotifier {
  List<CountryModel> _countries = [];
  List<TrafficSignModel> _signs = [];
  List<TrafficTipModel> _tips = [];
  List<String> _favoriteSignIds = [];
  List<String> _recentCountryIds = [];

  String _countryQuery = '';
  String _signQuery = '';

  TrafficDataProvider() {
    _initData();
  }

  List<CountryModel> get allCountries => _countries;
  List<TrafficSignModel> get allSigns => _signs;
  List<TrafficTipModel> get allTips => _tips;
  List<String> get favoriteSignIds => _favoriteSignIds;

  String get countryQuery => _countryQuery;
  String get signQuery => _signQuery;

  void _initData() {
    _countries = LocalJsonData.countries
        .map((c) => CountryModel.fromJson(c))
        .toList();
    _signs = LocalJsonData.signs
        .map((s) => TrafficSignModel.fromJson(s))
        .toList();
    _tips = LocalJsonData.tips.map((t) => TrafficTipModel.fromJson(t)).toList();
    _favoriteSignIds = StorageService.getFavorites();
    _recentCountryIds = StorageService.getRecentCountries();
    _selectedCountryId =
        StorageService.getSelectedCountry() ?? _detectCountryId();
    _isCountryAutoDetected = StorageService.getSelectedCountry() == null;
    _learnedIds = StorageService.getLearnedSigns().toSet();
    _quizzesDone = StorageService.getQuizzesDone();
    notifyListeners();
  }

  // ---------------- Learning progress ----------------

  Set<String> _learnedIds = {};
  int _quizzesDone = 0;

  /// Signs count as learned once their details page has been opened.
  bool isLearned(String signId) => _learnedIds.contains(signId);
  int get learnedCount => _learnedIds.length;
  int get quizzesDone => _quizzesDone;

  int learnedInCategory(String category) => _signs
      .where((s) => s.category == category && _learnedIds.contains(s.id))
      .length;

  Future<void> markLearned(String signId) async {
    if (!_learnedIds.add(signId)) return;
    await StorageService.setLearnedSigns(_learnedIds.toList());
    notifyListeners();
  }

  Future<void> markQuizDone() async {
    await StorageService.incrementQuizzesDone();
    _quizzesDone = StorageService.getQuizzesDone();
    notifyListeners();
  }

  /// The next sign to study, following [categoryOrder]; `null` when all
  /// signs are learned.
  TrafficSignModel? nextSignToLearn(List<String> categoryOrder) {
    for (final cat in categoryOrder) {
      for (final s in _signs) {
        if (s.category == cat && !_learnedIds.contains(s.id)) return s;
      }
    }
    for (final s in _signs) {
      if (!_learnedIds.contains(s.id)) return s;
    }
    return null;
  }

  /// The sign after [sign] in the same category (wraps around).
  TrafficSignModel? nextInCategory(TrafficSignModel sign) {
    final list = getSignsByCategory(sign.category);
    if (list.length < 2) return null;
    final i = list.indexWhere((s) => s.id == sign.id);
    return list[(i + 1) % list.length];
  }

  /// Marks the auto-detected country as confirmed by the user.
  Future<void> confirmCountry() => selectCountry(_selectedCountryId);

  // ---------------- Selected country ----------------

  late String _selectedCountryId;
  bool _isCountryAutoDetected = true;

  /// Whether the current country came from the device (not user-picked).
  bool get isCountryAutoDetected => _isCountryAutoDetected;

  CountryModel get selectedCountry =>
      getCountryById(_selectedCountryId) ?? _countries.first;

  Future<void> selectCountry(String countryId) async {
    _selectedCountryId = countryId;
    _isCountryAutoDetected = false;
    await StorageService.setSelectedCountry(countryId);
    notifyListeners();
  }

  // Device region code → country id in the local data set.
  static const Map<String, String> _regionToCountry = {
    'BD': 'bangladesh',
    'IN': 'india',
    'US': 'usa',
    'GB': 'uk',
    'JP': 'japan',
    'DE': 'germany',
    'CA': 'canada',
    'AU': 'australia',
    'AE': 'uae',
    'SA': 'saudi_arabia',
    'FR': 'france',
    'IT': 'italy',
    'CN': 'china',
  };

  // Fallback when the region is missing: guess from the device language.
  static const Map<String, String> _languageToCountry = {
    'bn': 'bangladesh',
    'hi': 'india',
    'ja': 'japan',
    'de': 'germany',
    'fr': 'france',
    'it': 'italy',
    'zh': 'china',
    'ar': 'saudi_arabia',
  };

  String _detectCountryId() {
    final locales = WidgetsBinding.instance.platformDispatcher.locales;
    for (final locale in locales) {
      final byRegion = _regionToCountry[locale.countryCode?.toUpperCase()];
      if (byRegion != null) return byRegion;
    }
    for (final locale in locales) {
      final byLanguage = _languageToCountry[locale.languageCode.toLowerCase()];
      if (byLanguage != null) return byLanguage;
    }
    return 'bangladesh';
  }

  // Favorites Management
  bool isFavorite(String signId) => _favoriteSignIds.contains(signId);

  Future<void> toggleFavorite(String signId) async {
    if (_favoriteSignIds.contains(signId)) {
      _favoriteSignIds.remove(signId);
    } else {
      _favoriteSignIds.add(signId);
    }
    await StorageService.saveFavorites(_favoriteSignIds);
    notifyListeners();
  }

  List<TrafficSignModel> get favoriteSigns {
    return _signs.where((s) => _favoriteSignIds.contains(s.id)).toList();
  }

  // Recents Management
  List<CountryModel> get recentCountries {
    return _recentCountryIds
        .map((id) => getCountryById(id))
        .whereType<CountryModel>()
        .toList();
  }

  Future<void> addRecentCountry(String countryId) async {
    await StorageService.addRecentCountry(countryId);
    _recentCountryIds = StorageService.getRecentCountries();
    notifyListeners();
  }

  // Searches
  void setCountryQuery(String query) {
    _countryQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void setSignQuery(String query) {
    _signQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  List<CountryModel> get filteredCountries {
    if (_countryQuery.isEmpty) return _countries;
    return _countries
        .where((c) => c.name.toLowerCase().contains(_countryQuery))
        .toList();
  }

  List<TrafficSignModel> get filteredSigns {
    if (_signQuery.isEmpty) return _signs;
    return _signs
        .where(
          (s) =>
              s.name.toLowerCase().contains(_signQuery) ||
              s.category.toLowerCase().contains(_signQuery) ||
              s.meaning.toLowerCase().contains(_signQuery),
        )
        .toList();
  }

  // Getters
  CountryModel? getCountryById(String id) {
    try {
      return _countries.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  TrafficSignModel? getSignById(String id) {
    try {
      return _signs.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  List<TrafficSignModel> getSignsByCategory(String category) {
    return _signs.where((s) => s.category == category).toList();
  }

  List<TrafficSignModel> getRelatedSigns(TrafficSignModel sign) {
    // Return other signs in the same category, excluding the current sign
    return _signs
        .where((s) => s.category == sign.category && s.id != sign.id)
        .take(3)
        .toList();
  }

  void refreshFromStorage() {
    _favoriteSignIds = StorageService.getFavorites();
    _recentCountryIds = StorageService.getRecentCountries();
    _learnedIds = StorageService.getLearnedSigns().toSet();
    _quizzesDone = StorageService.getQuizzesDone();
    notifyListeners();
  }
}
