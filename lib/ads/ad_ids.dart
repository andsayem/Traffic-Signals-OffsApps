import 'dart:io';
import 'package:flutter/foundation.dart';

class AdIds {
  AdIds._(); // no instances

  // ---------------- BANNER ----------------
  static String get banner {
    if (kReleaseMode) return 'ca-app-pub-1195883693665145/8169196259';
    return Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/6300978111'
        : 'ca-app-pub-3940256099942544/2934735716';
  }

  // ---------------- INTERSTITIAL ----------------
  static String get interstitial {
    if (kReleaseMode) return 'ca-app-pub-1195883693665145/9668191741';
    return Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/1033173712'
        : 'ca-app-pub-3940256099942544/4411468910';
  }

  // ---------------- APP OPEN ----------------
  static String get appOpen {
    if (kReleaseMode) return 'ca-app-pub-1195883693665145/5543032919';
    return Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/9257395921'
        : 'ca-app-pub-3940256099942544/5575463023';
  }

  // ---------------- REWARDED ----------------
  static String get rewarded {
    if (kReleaseMode) return 'ca-app-pub-1195883693665145/9288048250';
    return Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/5224354917'
        : 'ca-app-pub-3940256099942544/1712485313';
  }
}
