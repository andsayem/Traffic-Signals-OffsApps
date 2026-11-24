import 'package:flutter/widgets.dart';

import 'ad_service.dart';

/// Marks leaving [child] as a natural break point for an interstitial.
///
/// Counts one `AdService.registerBreak()` per screen visit, when the user
/// leaves it (not when it opens: right after tapping into a sign the user
/// keeps tapping, and an ad landing there drew accidental clicks). The
/// interstitial itself only shows every Nth break, outside the cooldown
/// and behind the countdown (see `AdService.init`).
class InterstitialBreak extends StatefulWidget {
  const InterstitialBreak({super.key, required this.child});

  final Widget child;

  @override
  State<InterstitialBreak> createState() => _InterstitialBreakState();
}

class _InterstitialBreakState extends State<InterstitialBreak> {
  @override
  void dispose() {
    // Let the back transition settle before a full-screen ad can appear.
    Future<void>.delayed(
      const Duration(milliseconds: 600),
      AdService.instance.registerBreak,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
