import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/theme_constants.dart';
import 'glass_card.dart';

class _OtherApp {
  final String name;
  final String packageId;
  final String iconAsset;

  const _OtherApp(this.name, this.packageId, this.iconAsset);
}

const _otherApps = [
  _OtherApp(
    'Duplicate Photo Remover',
    'com.andsayem.duplicate_remove',
    'assets/other_apps/duplicate_remove.png',
  ),
  _OtherApp(
    'QR & Barcode Studio',
    'com.andsayem.qrbarcodestudio',
    'assets/other_apps/qrbarcodestudio.png',
  ),
  _OtherApp(
    'Hidden Camera Detector',
    'com.andsayem.camera_detector',
    'assets/other_apps/camera_detector.png',
  ),
  _OtherApp(
    'Medi Reminder',
    'com.andsayem.medicineReminder',
    'assets/other_apps/medicine_reminder.png',
  ),
  _OtherApp(
    'Jigsaw Puzzle - Cardscapes',
    'com.andsayem.puzzle',
    'assets/other_apps/puzzle.png',
  ),
  _OtherApp(
    'Income & Expense Tracker',
    'my.daily.transaction',
    'assets/other_apps/daily_transaction.png',
  ),
];

class OtherAppsCard extends StatelessWidget {
  const OtherAppsCard({super.key});

  Future<void> _openStore(String packageId) async {
    // Try the Play Store app first, fall back to the web listing.
    final marketUri = Uri.parse('market://details?id=$packageId');
    final webUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$packageId',
    );
    try {
      if (await launchUrl(marketUri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {}
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.apps_rounded,
                color: ThemeConstants.signalGreen,
                size: 22,
              ),
              SizedBox(width: 12),
              Text(
                'More Apps from Us',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _otherApps.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final app = _otherApps[index];
                return InkWell(
                  onTap: () => _openStore(app.packageId),
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 76,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            app.iconAsset,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          app.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10.5,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white70
                                : ThemeConstants.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
