import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:traffic_signal_symbols/ads/adaptive_banner_ad_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/traffic_provider.dart';
import '../utils/translations.dart';
import '../utils/theme_constants.dart';
import '../widgets/ad_free_reward_card.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/motion.dart';
import '../widgets/other_apps_card.dart';
import 'subscription_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBackground(
      appBar: AppBar(title: Text(context.tr('settings'))),
      child: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: _stagger([
              // Go Pro Card
              Consumer<SubscriptionProvider>(
                builder: (context, subscription, child) {
                  if (subscription.isPro) {
                    return GlassCard(
                      borderRadius: 18,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.workspace_premium_rounded,
                            color: ThemeConstants.signalYellow,
                            size: 26,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Ads removed — thank you for your support!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white
                                    : ThemeConstants.lightTextPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return GlassCard(
                    onTap: () => SubscriptionScreen.show(context),
                    borderRadius: 18,
                    padding: const EdgeInsets.all(16),
                    customColor: ThemeConstants.signalYellow.withValues(
                      alpha: isDark ? 0.14 : 0.16,
                    ),
                    customBorderColor: ThemeConstants.signalYellow.withValues(
                      alpha: 0.4,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                ThemeConstants.signalYellow,
                                ThemeConstants.signalOrange,
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Remove Ads',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: isDark
                                      ? Colors.white
                                      : ThemeConstants.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Use the whole app without any ads',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white70
                                      : ThemeConstants.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: ThemeConstants.signalOrange,
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Big banner ad as the second section, visible without scrolling
              const AdaptiveBannerAdWidget(),
              const SizedBox(height: 16),

              // Rewarded "remove ads for a while" card (non-Pro only)
              Consumer<SubscriptionProvider>(
                builder: (context, subscription, child) {
                  if (subscription.isPro) return const SizedBox.shrink();
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: AdFreeRewardCard(),
                  );
                },
              ),

              // Theme Toggle Card
              GlassCard(
                borderRadius: 18,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          appProvider.isDarkTheme
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: ThemeConstants.signalYellow,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          context.tr('dark_mode'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
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
              _buildLanguageCard(context, appProvider),

              const SizedBox(height: 16),

              // Reset Data Card
              GlassCard(
                borderRadius: 18,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.delete_forever_rounded,
                    color: ThemeConstants.signalRed,
                  ),
                  title: Text(
                    context.tr('reset_data'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: ThemeConstants.signalRed,
                    ),
                  ),
                  onTap: () => _showResetConfirmation(context, appProvider),
                ),
              ),

              const SizedBox(height: 16),

              // More Apps Card
              const OtherAppsCard(),

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
                          decoration: const BoxDecoration(
                            color: ThemeConstants.signalRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: ThemeConstants.signalYellow,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: ThemeConstants.signalGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr('app_title'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${context.tr('version')}: 1.0.0+1",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 8),
                    Text(
                      "Developed offline for cross-country driving education.",
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14),

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
                          const Icon(
                            Icons.info_outline_rounded,
                            color: ThemeConstants.signalYellow,
                            size: 20,
                          ),
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
                          color: isDark
                              ? Colors.white70
                              : ThemeConstants.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 10),
              // Sources Card
              GlassCard(
                borderRadius: 18,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.link_rounded,
                          color: ThemeConstants.signalBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          context.tr('sources_title'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...Provider.of<TrafficDataProvider>(
                      context,
                    ).allCountries.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => launchUrl(
                            Uri.parse(c.sourceUrl),
                            mode: LaunchMode.externalApplication,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            children: [
                              Text(
                                c.flagEmoji,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  c.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
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
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('disclaimer'),
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.4,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ]),
          );
        },
      ),
    );
  }

  static const _languages = [
    ('en', '🇬🇧', 'English'),
    ('bn', '🇧🇩', 'বাংলা (Bangla)'),
    ('es', '🇪🇸', 'Español (Spanish)'),
    ('fr', '🇫🇷', 'Français (French)'),
    ('de', '🇩🇪', 'Deutsch (German)'),
    ('ja', '🇯🇵', '日本語 (Japanese)'),
    ('ar', '🇸🇦', 'العربية (Arabic)'),
    ('hi', '🇮🇳', 'हिन्दी (Hindi)'),
    ('it', '🇮🇹', 'Italiano (Italian)'),
    ('zh', '🇨🇳', '中文 (Chinese)'),
  ];

  Widget _buildLanguageCard(BuildContext context, AppProvider appProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
      child: Row(
        children: [
          const Icon(Icons.language_rounded, color: ThemeConstants.signalBlue),
          const SizedBox(width: 16),
          Text(
            context.tr('language'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: ThemeConstants.signalBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ThemeConstants.signalBlue.withValues(alpha: 0.35),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: appProvider.languageCode,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(14),
                  dropdownColor: isDark
                      ? ThemeConstants.darkBgStart
                      : Colors.white,
                  menuMaxHeight: 420,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: ThemeConstants.signalBlue,
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white
                        : ThemeConstants.lightTextPrimary,
                  ),
                  items: [
                    for (final (code, flag, name) in _languages)
                      DropdownMenuItem(
                        value: code,
                        child: Text(
                          '$flag  $name',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (code) {
                    if (code != null) appProvider.setLanguage(code);
                  },
                ),
              ),
            ),
          ),
        ],
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
              child: Text(
                context.tr('cancel'),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                final trafficProvider = Provider.of<TrafficDataProvider>(
                  context,
                  listen: false,
                );
                appProvider.resetProgress().then((_) {
                  trafficProvider.refreshFromStorage();
                });
                Navigator.pop(context);
              },
              child: Text(
                context.tr('confirm'),
                style: const TextStyle(
                  color: ThemeConstants.signalRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Staggers each settings card in; spacers pass through untouched.
List<Widget> _stagger(List<Widget> children) {
  var i = 0;
  return [
    for (final child in children)
      child is SizedBox ? child : FadeSlideIn(index: i++, child: child),
  ];
}
