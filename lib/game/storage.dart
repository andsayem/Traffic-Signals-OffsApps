import 'package:shared_preferences/shared_preferences.dart';

import 'data/levels.dart';

/// Stars and best scores per vehicle and level.
class Progress {
  static SharedPreferences? _p;

  static Future<void> init() async {
    _p = await SharedPreferences.getInstance();
  }

  static String _starsKey(String v, int level) => 'stars_${v}_$level';
  static String _scoreKey(String v, int level) => 'score_${v}_$level';

  static int stars(String vehicleId, int level) =>
      _p?.getInt(_starsKey(vehicleId, level)) ?? 0;

  static int? bestScore(String vehicleId, int level) =>
      _p?.getInt(_scoreKey(vehicleId, level));

  static String _adUnlockKey(String v, int level) => 'adunlock_${v}_$level';

  static bool unlocked(String vehicleId, int level) =>
      level == 1 ||
      stars(vehicleId, level - 1) > 0 ||
      (_p?.getBool(_adUnlockKey(vehicleId, level)) ?? false);

  /// Unlocks [level] early after the player watched a rewarded ad.
  static Future<void> unlockWithAd(String vehicleId, int level) async {
    final p = _p ??= await SharedPreferences.getInstance();
    await p.setBool(_adUnlockKey(vehicleId, level), true);
  }

  static int totalStars(String vehicleId) => [
    for (final l in levels) stars(vehicleId, l.number),
  ].fold(0, (a, b) => a + b);

  static int levelsDone(String vehicleId) =>
      levels.where((l) => stars(vehicleId, l.number) > 0).length;

  /// Saves a finished level. Returns true when [score] is a new best.
  static Future<bool> record(
    String vehicleId,
    int level,
    int stars,
    int score,
  ) async {
    final p = _p ??= await SharedPreferences.getInstance();
    if (stars > Progress.stars(vehicleId, level)) {
      await p.setInt(_starsKey(vehicleId, level), stars);
    }
    final best = bestScore(vehicleId, level);
    if (best == null || score > best) {
      await p.setInt(_scoreKey(vehicleId, level), score);
      return true;
    }
    return false;
  }

  static Future<void> reset() async {
    final p = _p ??= await SharedPreferences.getInstance();
    for (final k in p.getKeys().toList()) {
      if (k.startsWith('stars_') ||
          k.startsWith('score_') ||
          k.startsWith('adunlock_')) {
        await p.remove(k);
      }
    }
  }
}

String formatDuration(Duration d) {
  final m = d.inMinutes.toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
