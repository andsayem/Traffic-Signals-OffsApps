import 'dart:async';

import 'package:flutter/material.dart';
import '../utils/theme_constants.dart';
import 'package:upgrader/upgrader.dart';

/// Play Store update prompt with a forced-update rule:
///
/// - Major or minor bump (1.5.6 -> 1.6.1, 1.5.6 -> 2.0.0): update is
///   required. The prompt has no Later / Ignore and cannot be dismissed.
/// - Patch-only bump (1.5.6 -> 1.5.8): optional, the user can skip it.
class AppUpgrader extends Upgrader {
  AppUpgrader() : super(debugDisplayAlways: false);

  @override
  bool blocked() => super.blocked() || isMajorOrMinorUpdate();

  bool isMajorOrMinorUpdate() {
    final store = _majorMinor(currentAppStoreVersion);
    final installed = _majorMinor(currentInstalledVersion);
    if (store == null || installed == null) return false;
    if (store.$1 != installed.$1) return store.$1 > installed.$1;
    return store.$2 > installed.$2;
  }

  static (int, int)? _majorMinor(String? version) {
    if (version == null) return null;
    final parts = version.split('+').first.split('.');
    if (parts.length < 2) return null;
    final major = int.tryParse(parts[0]);
    final minor = int.tryParse(parts[1]);
    if (major == null || minor == null) return null;
    return (major, minor);
  }
}

/// Shows the update prompt as an overlay above the app's Navigator.
///
/// Sits above the Navigator (in MaterialApp.builder), so the prompt stays
/// visible across every route change.
class UpdateGate extends StatefulWidget {
  const UpdateGate({super.key, required this.upgrader, required this.child});

  final AppUpgrader upgrader;
  final Widget child;

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> {
  StreamSubscription<UpgraderState>? _sub;
  bool _visible = false;
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    _sub = widget.upgrader.stateStream.listen((_) => _evaluate());
    widget.upgrader.initialize().then((_) => _evaluate());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _evaluate() {
    if (!mounted || _visible) return;
    if (!widget.upgrader.shouldDisplayUpgrade()) return;
    widget.upgrader.saveLastAlerted();
    setState(() {
      _visible = true;
      _blocked = widget.upgrader.blocked();
    });
  }

  void _hide() => setState(() => _visible = false);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_visible) Positioned.fill(child: _buildPrompt(context)),
      ],
    );
  }

  Widget _buildPrompt(BuildContext context) {
    final upgrader = widget.upgrader;
    final storeVersion = upgrader.currentAppStoreVersion ?? '';
    final installed = upgrader.currentInstalledVersion ?? '';
    const primary = ThemeConstants.signalRed;

    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    color: primary,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _blocked ? 'Update Required' : 'Update Available',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _blocked
                      ? 'Version $storeVersion is required to keep using '
                            'Traffic Signals. You have $installed.'
                      : 'Version $storeVersion is available. You have '
                            '$installed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // A required update stays on screen: after the user
                    // comes back from the Play Store without updating, the
                    // prompt is still there.
                    onPressed: upgrader.sendUserToAppStore,
                    child: const Text(
                      'Update Now',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                if (!_blocked)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          upgrader.saveIgnored();
                          _hide();
                        },
                        child: Text(
                          'Ignore',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _hide,
                        child: const Text(
                          'Later',
                          style: TextStyle(color: primary),
                        ),
                      ),
                    ],
                  )
                else
                  const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
