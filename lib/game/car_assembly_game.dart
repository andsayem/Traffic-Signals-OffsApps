import 'package:flutter/material.dart';

import '../ads/footer_banner_ad.dart';

import 'l10n/strings.dart';
import 'screens/home_screen.dart';
import 'settings.dart';
import 'storage.dart';
import 'theme.dart';

/// Entry point for the Car Assembly mini-game hosted inside the Traffic
/// Signals app. The game keeps its own theme, language strings, settings
/// and progress (all under `lib/game/`).
class CarAssemblyGame extends StatefulWidget {
  const CarAssemblyGame({super.key});

  static bool _loaded = false;

  /// Opens the game. Loads its settings/progress on first use and follows
  /// the host app's language when the game supports it.
  static Future<void> open(BuildContext context, {String? hostLanguage}) async {
    if (!_loaded) {
      await Future.wait([settings.load(), Progress.init()]);
      _loaded = true;
    }
    if (hostLanguage != null && translations.containsKey(hostLanguage)) {
      appLang.value = hostLanguage;
    }
    if (!context.mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CarAssemblyGame()));
  }

  @override
  State<CarAssemblyGame> createState() => _CarAssemblyGameState();
}

class _CarAssemblyGameState extends State<CarAssemblyGame> {
  @override
  void initState() {
    super.initState();
    appLang.addListener(_relabel);
  }

  @override
  void dispose() {
    appLang.removeListener(_relabel);
    super.dispose();
  }

  /// Rebuilds the game's widgets (even const ones) so every [tr] call picks
  /// up a language change made in the game's own settings.
  void _relabel() {
    void rebuild(Element e) {
      e.markNeedsBuild();
      e.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }

  final _navKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Nested Navigator so the game's own screens (levels, assembly,
    // settings) share its theme. System back pops inside the game first;
    // on the game's home it leaves the game.
    return Theme(
      data: buildTheme(),
      child: ColoredBox(
        color: AppColors.bgBottom,
        child: Column(
          children: [
            Expanded(
              // The footer below handles the bottom inset, so the game's
              // own SafeAreas don't add a second gap above the banner.
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: true,
                child: NavigatorPopHandler(
                  onPopWithResult: (_) => _navKey.currentState?.maybePop(),
                  child: Navigator(
                    key: _navKey,
                    onGenerateRoute: (_) =>
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                  ),
                ),
              ),
            ),
            // Footer banner on every game screen.
            const SafeArea(
              top: false,
              child: FooterBannerAd(background: AppColors.bgBottom),
            ),
          ],
        ),
      ),
    );
  }
}
