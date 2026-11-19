import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asks for a Play rating at a few good moments, and powers the
/// "Rate app" / "Share app" buttons in Settings.
class ReviewService {
  static const String playUrl =
      'https://play.google.com/store/apps/details?id=com.andsayem.traffic_signal_symbols';

  static const String _keyAskedAt = 'review_asked_at_quiz';

  /// Quiz counts after which we may ask. Play also rate-limits the dialog,
  /// so it will not appear every time.
  static const List<int> _askAfterQuizzes = [2, 6, 15];

  /// Call after a quiz is finished, with the new total of finished quizzes.
  static Future<void> maybeAskAfterQuiz(int quizzesDone) async {
    if (!_askAfterQuizzes.contains(quizzesDone)) return;
    final prefs = await SharedPreferences.getInstance();
    if ((prefs.getInt(_keyAskedAt) ?? 0) >= quizzesDone) return;
    await prefs.setInt(_keyAskedAt, quizzesDone);

    // Let the results screen settle first.
    await Future.delayed(const Duration(seconds: 2));
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      }
    } catch (_) {
      // Never let a review prompt break the app.
    }
  }

  static Future<void> openStore() async {
    try {
      await InAppReview.instance.openStoreListing();
    } catch (_) {}
  }

  static Future<void> shareApp(String message) async {
    await Share.share('$message\n$playUrl');
  }
}
