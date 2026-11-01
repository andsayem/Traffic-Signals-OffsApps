import 'package:flutter/widgets.dart';

import 'ad_service.dart';

/// Marks opening [child] as a natural break point for an interstitial.
///
/// Counts one `AdService.registerBreak()` per screen open; the interstitial
/// itself only shows every 2nd break, outside the cooldown and behind the
/// countdown (see `AdService.init`).
class InterstitialBreak extends StatefulWidget {
  const InterstitialBreak({super.key, required this.child});

  final Widget child;

  @override
  State<InterstitialBreak> createState() => _InterstitialBreakState();
}

class _InterstitialBreakState extends State<InterstitialBreak> {
  @override
  void initState() {
    super.initState();
    // Let the route transition settle before a full-screen ad can appear.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AdService.instance.registerBreak();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
