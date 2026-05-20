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
    _tips = LocalJsonData.tips
        .map((t) => TrafficTipModel.fromJson(t))
        .toList();
    _favoriteSignIds = StorageService.getFavorites();
    _recentCountryIds = StorageService.getRecentCountries();
    notifyListeners();
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
        .where((s) =>
            s.name.toLowerCase().contains(_signQuery) ||
            s.category.toLowerCase().contains(_signQuery) ||
            s.meaning.toLowerCase().contains(_signQuery))
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
    notifyListeners();
  }
}
