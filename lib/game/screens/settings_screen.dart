import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../settings.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _reset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('reset_progress')),
        content: Text(tr('reset_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(tr('reset')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await Progress.reset();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('progress_reset'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: garageGradient,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: settings,
            builder: (context, _) => Column(
              children: [
                ScreenBar(title: tr('settings')),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _Section(
                        icon: Icons.language_rounded,
                        title: tr('language'),
                        child: RadioGroup<String>(
                          groupValue: settings.lang,
                          onChanged: (c) {
                            if (c != null) settings.setLang(c);
                          },
                          child: Column(
                            children: [
                              for (final l in languages)
                                RadioListTile<String>(
                                  value: l.code,
                                  title: Text(l.name),
                                  subtitle: l.code == 'en'
                                      ? null
                                      : Text(l.english),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Section(
                        child: Column(
                          children: [
                            SwitchListTile(
                              secondary: const Icon(Icons.vibration_rounded),
                              title: Text(tr('vibration')),
                              value: settings.haptics,
                              onChanged: settings.setHaptics,
                            ),
                            SwitchListTile(
                              secondary: const Icon(Icons.label_rounded),
                              title: Text(tr('show_names')),
                              value: settings.labels,
                              onChanged: settings.setLabels,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Section(
                        child: ListTile(
                          leading: const Icon(
                            Icons.restart_alt_rounded,
                            color: Colors.redAccent,
                          ),
                          title: Text(tr('reset_progress')),
                          onTap: () => _reset(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.child, this.icon, this.title});

  final Widget child;
  final IconData? icon;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(
                    title!,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          child,
        ],
      ),
    );
  }
}
