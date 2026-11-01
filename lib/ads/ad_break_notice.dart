import 'dart:async';

import 'package:flutter/material.dart';

import 'root_navigator_key.dart';

/// A full-screen "Ad starts in N" countdown shown right before every
/// interstitial (wired up via `AdMobSettings.beforeInterstitial`).
///
/// It warns the user so a full-screen ad never lands mid-tap, which keeps
/// accidental clicks (and the invalid-traffic penalties they bring) down.
class AdBreakNotice {
  AdBreakNotice._();

  static const seconds = 2;

  /// Shows the countdown and completes once it has run out. Completes
  /// immediately when there is no navigator to show it on.
  static Future<void> show() async {
    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (_, _, _) =>
          const PopScope(canPop: false, child: _CountdownPage()),
    );
  }
}

class _CountdownPage extends StatefulWidget {
  const _CountdownPage();

  @override
  State<_CountdownPage> createState() => _CountdownPageState();
}

class _CountdownPageState extends State<_CountdownPage> {
  int _left = AdBreakNotice.seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_left <= 1) {
        timer.cancel();
        if (mounted) Navigator.of(context).pop();
        return;
      }
      setState(() => _left--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ad starts in', style: theme.textTheme.titleLarge),
            const SizedBox(height: 28),
            SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1, end: 0),
                    duration: const Duration(seconds: AdBreakNotice.seconds),
                    builder: (_, value, _) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  Center(
                    child: Text(
                      '$_left',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Loading advertisement...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
