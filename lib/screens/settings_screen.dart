import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_provider.dart';
import '../providers/traffic_provider.dart';
import '../utils/translations.dart';
import '../utils/theme_constants.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      appBar: AppBar(
        title: Text(context.tr('settings')),
      ),
      child: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Theme Toggle Card
              GlassCard(
                borderRadius: 18,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          appProvider.isDarkTheme ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: ThemeConstants.signalYellow,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          context.tr('dark_mode'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    Switch(
                      value: appProvider.isDarkTheme,
                      activeThumbColor: ThemeConstants.signalRed,
                      onChanged: (val) {
                        appProvider.setDarkTheme(val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Language Selector Card
              GlassCard(
                borderRadius: 18,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.language_rounded, color: ThemeConstants.signalBlue),
                        const SizedBox(width: 16),
                        Text(
                          context.tr('language'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildLanguageOption(context, appProvider, 'English', 'en'),
                    _buildLanguageOption(context, appProvider, 'বাংলা (Bangla)', 'bn'),
                    _buildLanguageOption(context, appProvider, 'Español (Spanish)', 'es'),
                    _buildLanguageOption(context, appProvider, 'Français (French)', 'fr'),
                    _buildLanguageOption(context, appProvider, 'Deutsch (German)', 'de'),
                    _buildLanguageOption(context, appProvider, '日本語 (Japanese)', 'ja'),
                    _buildLanguageOption(context, appProvider, 'العربية (Arabic)', 'ar'),
                    _buildLanguageOption(context, appProvider, 'हिन्दी (Hindi)', 'hi'),
                    _buildLanguageOption(context, appProvider, 'Italiano (Italian)', 'it'),
                    _buildLanguageOption(context, appProvider, '中文 (Chinese)', 'zh'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Reset Data Card
              GlassCard(
                borderRadius: 18,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_forever_rounded, color: ThemeConstants.signalRed),
                  title: Text(
                    context.tr('reset_data'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: ThemeConstants.signalRed),
                  ),
                  onTap: () => _showResetConfirmation(context, appProvider),
                ),
              ),

              const SizedBox(height: 24),

              // App Version Info Card
              GlassCard(
                borderRadius: 18,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(color: ThemeConstants.signalRed, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(color: ThemeConstants.signalYellow, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(color: ThemeConstants.signalGreen, shape: BoxShape.circle),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr('app_title'),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${context.tr('version')}: 1.0.0+1",
                      style: const TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 8),
                    const Text(
                      "Developed offline for cross-country driving education.",
                      style: TextStyle(fontSize: 11, color: Colors.white38),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Disclaimer Card
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: GlassCard(
                  borderRadius: 18,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: ThemeConstants.signalYellow, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            "Disclaimer",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: ThemeConstants.signalYellow,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.tr('disclaimer'),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sources Card
              GlassCard(
                borderRadius: 18,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.link_rounded, color: ThemeConstants.signalBlue, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          context.tr('sources_title'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...Provider.of<TrafficDataProvider>(context).allCountries.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => launchUrl(Uri.parse(c.sourceUrl), mode: LaunchMode.externalApplication),
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          children: [
                            Text(c.flagEmoji, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                c.name,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                c.sourceUrl,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: ThemeConstants.signalBlue,
                                  decoration: TextDecoration.underline,
                                ),
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                    const SizedBox(height: 4),
                      Text(
                        context.tr('disclaimer'),
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.4,
                          color: Colors.white38,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    AppProvider appProvider,
    String name,
    String code,
  ) {
    final isSelected = appProvider.languageCode == code;
    return InkWell(
      onTap: () => appProvider.setLanguage(code),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? ThemeConstants.signalBlue.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? ThemeConstants.signalBlue : Colors.white70,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: ThemeConstants.signalBlue, size: 18),
          ],
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Text(
            context.tr('reset_data'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            context.tr('reset_confirm'),
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('cancel'), style: const TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                final trafficProvider = Provider.of<TrafficDataProvider>(context, listen: false);
                appProvider.resetProgress().then((_) {
                  trafficProvider.refreshFromStorage();
                });
                Navigator.pop(context);
              },
              child: Text(context.tr('confirm'), style: const TextStyle(color: ThemeConstants.signalRed, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
