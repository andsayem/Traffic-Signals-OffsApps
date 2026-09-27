import 'package:flutter/material.dart';
import '../utils/theme_constants.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const AppBackground({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [ThemeConstants.darkBgStart, ThemeConstants.darkBgEnd]
              : [ThemeConstants.lightBgStart, ThemeConstants.lightBgEnd],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        // Keep content clear of notches, the status bar (when there's no
        // app bar) and the system navigation / gesture bar.
        body: SafeArea(top: appBar == null, child: child),
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}
