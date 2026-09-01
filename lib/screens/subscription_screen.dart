import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import '../providers/subscription_provider.dart';
import '../services/purchase_service.dart';
import '../utils/theme_constants.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';

/// The Pro paywall: shown automatically on app launch (if not subscribed)
/// and whenever the user taps a "Go Pro" entry point.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  /// Pushes the paywall as a full-screen modal. Use this everywhere instead
  /// of constructing the screen directly.
  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const SubscriptionScreen(),
      ),
    );
  }

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String _selectedPlan = SubscriptionIds.yearly;
  bool _wasProOnOpen = false;
  bool _hasClosedForSuccess = false;

  static const _features = [
    ('Ad-free experience', Icons.block_rounded),
    ('Unlock all premium features', Icons.workspace_premium_rounded),
    ('Unlimited access', Icons.all_inclusive_rounded), 
  ];

  @override
  void initState() {
    super.initState();
    _wasProOnOpen = context.read<SubscriptionProvider>().isPro;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<SubscriptionProvider>();

    if (!_wasProOnOpen && provider.isPro && !_hasClosedForSuccess) {
      _hasClosedForSuccess = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You're Pro now — enjoy the ad-free experience!"),
            backgroundColor: ThemeConstants.signalGreen,
          ),
        );
      });
    }

    return AppBackground(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: provider.isPurchasing
                ? null
                : () async {
                    await provider.restore();
                    if (!context.mounted) return;
                    if (provider.isPro) return; // handled by the listener above
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No previous purchase found.')),
                    );
                  },
            child: const Text('Restore'),
          ),
        ],
      ),
      child: SafeArea(
        child: provider.isPro ? _buildAlreadyPro(isDark) : _buildPaywall(context, provider, isDark),
      ),
    );
  }

  Widget _buildAlreadyPro(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium_rounded, color: ThemeConstants.signalYellow, size: 84),
            const SizedBox(height: 20),
            const Text(
              "You're already Pro!",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Thanks for supporting Traffic Signals & Signs. Enjoy the full ad-free experience.',
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaywall(BuildContext context, SubscriptionProvider provider, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [ThemeConstants.signalYellow, ThemeConstants.signalOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ThemeConstants.signalYellow.withValues(alpha: 0.4),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 48),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Traffic Signals PRO',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
          ),
          const SizedBox(height: 6),
          Text(
            'Unlock the complete ad-free experience',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(height: 24),

          // Feature list
          GlassCard(
            borderRadius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              children: [
                for (int i = 0; i < _features.length; i++) ...[
                  if (i > 0) const Divider(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: ThemeConstants.signalGreen.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_features[i].$2, color: ThemeConstants.signalGreen, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _features[i].$1,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                        ),
                      ),
                      const Icon(Icons.check_circle_rounded, color: ThemeConstants.signalGreen, size: 20),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Plan selection
          if (provider.isLoadingProducts)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(color: ThemeConstants.signalGreen)),
            )
          else ...[
            _PlanCard(
              id: SubscriptionIds.yearly,
              label: 'Yearly',
              badge: _savingsBadge(provider),
              product: provider.yearlyProduct,
              periodSuffix: '/year',
              selected: _selectedPlan == SubscriptionIds.yearly,
              isDark: isDark,
              onTap: () => setState(() => _selectedPlan = SubscriptionIds.yearly),
            ),
            const SizedBox(height: 12),
            _PlanCard(
              id: SubscriptionIds.monthly,
              label: 'Monthly',
              product: provider.monthlyProduct,
              periodSuffix: '/month',
              selected: _selectedPlan == SubscriptionIds.monthly,
              isDark: isDark,
              onTap: () => setState(() => _selectedPlan = SubscriptionIds.monthly),
            ),
          ],

          if (provider.error != null) ...[
            const SizedBox(height: 16),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ThemeConstants.signalRed, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ],

          const SizedBox(height: 24),

          SizedBox(
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConstants.signalGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: provider.isPurchasing || provider.isLoadingProducts
                  ? null
                  : () => provider.purchase(_selectedPlan),
              child: provider.isPurchasing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  : const Text('Continue', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),

          const SizedBox(height: 14),
          Text(
            'Auto-renewable subscription. Cancel anytime from your app store account settings.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
          ),
        ],
      ),
    );
  }

  /// Computes a "Save X%" badge for the yearly plan vs. paying monthly for
  /// 12 months, when both product prices are available from the store.
  String? _savingsBadge(SubscriptionProvider provider) {
    final monthly = provider.monthlyProduct;
    final yearly = provider.yearlyProduct;
    if (monthly == null || yearly == null) return 'BEST VALUE';
    final monthlyCost = monthly.rawPrice * 12;
    if (monthlyCost <= 0 || yearly.rawPrice <= 0 || yearly.rawPrice >= monthlyCost) {
      return 'BEST VALUE';
    }
    final savings = (1 - (yearly.rawPrice / monthlyCost)) * 100;
    return 'SAVE ${savings.round()}%';
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.id,
    required this.label,
    required this.periodSuffix,
    required this.selected,
    required this.isDark,
    required this.onTap,
    this.product,
    this.badge,
  });

  final String id;
  final String label;
  final String periodSuffix;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  final ProductDetails? product;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final priceText = product != null ? '${product!.price}$periodSuffix' : 'Unavailable';

    return GlassCard(
      onTap: product == null ? null : onTap,
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      customColor: selected
          ? ThemeConstants.signalGreen.withValues(alpha: isDark ? 0.16 : 0.12)
          : null,
      customBorderColor: selected ? ThemeConstants.signalGreen : null,
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
            color: selected ? ThemeConstants.signalGreen : (isDark ? Colors.white38 : Colors.black38),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: ThemeConstants.signalOrange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  product?.description ?? 'Not available on this device',
                  style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.black45),
                ),
              ],
            ),
          ),
          Text(
            priceText,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: product == null ? (isDark ? Colors.white38 : Colors.black38) : null,
            ),
          ),
        ],
      ),
    );
  }
}
