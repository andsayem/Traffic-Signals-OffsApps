import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import '../providers/subscription_provider.dart';
import '../services/purchase_service.dart';
import '../utils/theme_constants.dart';
import '../widgets/motion.dart';

const _gold = Color(0xFFFFC53D);
const _goldDeep = Color(0xFFFF8A00);

/// The Pro paywall: shown automatically on app launch (if not subscribed)
/// and whenever the user taps a "Go Pro" entry point.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  /// Opens the "Remove Ads" offer as a popup dialog. Use this everywhere
  /// instead of constructing the screen directly.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => const SubscriptionScreen(),
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
    (
      'No ads',
      'Anywhere in the app',
      Icons.block_rounded,
      ThemeConstants.signalRed,
    ),
    (
      'All premium',
      'Every feature unlocked',
      Icons.workspace_premium_rounded,
      _gold,
    ),
    (
      'Unlimited',
      'Learn without limits',
      Icons.all_inclusive_rounded,
      ThemeConstants.signalBlue,
    ),
    (
      'Cancel anytime',
      'From Google Play',
      Icons.event_available_rounded,
      ThemeConstants.signalGreen,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _wasProOnOpen = context.read<SubscriptionProvider>().isPro;
  }

  Future<void> _restore(SubscriptionProvider provider) async {
    await provider.restore();
    if (!mounted) return;
    if (provider.isPro) return; // handled by the listener in build
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No previous purchase found.')),
    );
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
            content: Text('Ads removed — enjoy the app ad-free!'),
            backgroundColor: ThemeConstants.signalGreen,
          ),
        );
      });
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _gold.withValues(alpha: 0.35)),
          gradient: RadialGradient(
            center: const Alignment(0, -0.75),
            radius: 1.2,
            colors: [
              _gold.withValues(alpha: isDark ? 0.22 : 0.28),
              isDark ? ThemeConstants.darkBgStart : ThemeConstants.lightBgStart,
              isDark ? ThemeConstants.darkBgEnd : ThemeConstants.lightBgEnd,
            ],
            stops: const [0, 0.5, 1],
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    if (!provider.isPro)
                      TextButton(
                        onPressed: provider.isPurchasing
                            ? null
                            : () => _restore(provider),
                        child: Text(
                          'Restore',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Flexible(
                child: provider.isPro
                    ? _buildAlreadyPro(isDark)
                    : _buildPaywall(context, provider, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlreadyPro(bool isDark) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _ProBadge(size: 84),
            const SizedBox(height: 16),
            const Text(
              'Ads are removed!',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Thanks for supporting Traffic Signals & Signs. Enjoy the app without any ads.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaywall(
    BuildContext context,
    SubscriptionProvider provider,
    bool isDark,
  ) {
    final selectedProduct = _selectedPlan == SubscriptionIds.yearly
        ? provider.yearlyProduct
        : provider.monthlyProduct;
    final secondary = isDark
        ? ThemeConstants.darkTextSecondary
        : ThemeConstants.lightTextSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: _ProBadge(size: 72)),
                const SizedBox(height: 6),
                FadeSlideIn(
                  child: Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (r) => const LinearGradient(
                          colors: [_gold, _goldDeep],
                        ).createShader(r),
                        child: const Text(
                          'Remove Ads',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enjoy the whole app without a single ad',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: secondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Features 2×2
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.3,
                  children: [
                    for (var i = 0; i < _features.length; i++)
                      FadeSlideIn(
                        index: i + 1,
                        child: _FeatureTile(
                          title: _features[i].$1,
                          subtitle: _features[i].$2,
                          icon: _features[i].$3,
                          color: _features[i].$4,
                          isDark: isDark,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Plans
                if (provider.isLoadingProducts)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: CircularProgressIndicator(color: _gold),
                    ),
                  )
                else ...[
                  FadeSlideIn(
                    index: 5,
                    child: _PlanCard(
                      label: 'Yearly',
                      badge: _savingsBadge(provider),
                      product: provider.yearlyProduct,
                      periodSuffix: '/year',
                      perMonth: _perMonth(provider.yearlyProduct),
                      selected: _selectedPlan == SubscriptionIds.yearly,
                      isDark: isDark,
                      onTap: () => setState(
                        () => _selectedPlan = SubscriptionIds.yearly,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    index: 6,
                    child: _PlanCard(
                      label: 'Monthly',
                      product: provider.monthlyProduct,
                      periodSuffix: '/month',
                      perMonth: 'Flexible, billed monthly',
                      selected: _selectedPlan == SubscriptionIds.monthly,
                      isDark: isDark,
                      onTap: () => setState(
                        () => _selectedPlan = SubscriptionIds.monthly,
                      ),
                    ),
                  ),
                ],

                if (provider.error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ThemeConstants.signalRed,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Sticky CTA
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            children: [
              _CtaButton(
                busy: provider.isPurchasing,
                enabled:
                    !provider.isPurchasing &&
                    !provider.isLoadingProducts &&
                    selectedProduct != null,
                label: selectedProduct == null
                    ? 'Continue'
                    : 'Continue · ${selectedProduct.price}',
                onTap: () => provider.purchase(_selectedPlan),
              ),
              const SizedBox(height: 10),
              FittedBox(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_rounded, size: 13, color: secondary),
                    const SizedBox(width: 4),
                    Text(
                      'Secure payment via Google Play',
                      style: TextStyle(fontSize: 11, color: secondary),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.autorenew_rounded, size: 13, color: secondary),
                    const SizedBox(width: 4),
                    Text(
                      'Cancel anytime',
                      style: TextStyle(fontSize: 11, color: secondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Auto-renewable subscription. Manage it in your Play Store account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// "≈ BDT 66.67/month" for the yearly plan, when the store gives a price.
  String _perMonth(ProductDetails? yearly) {
    if (yearly == null || yearly.rawPrice <= 0) return 'Billed once a year';
    final monthly = (yearly.rawPrice / 12).toStringAsFixed(2);
    return '≈ ${yearly.currencySymbol}$monthly/month · billed yearly';
  }

  /// Computes a "Save X%" badge for the yearly plan vs. paying monthly for
  /// 12 months, when both product prices are available from the store.
  String? _savingsBadge(SubscriptionProvider provider) {
    final monthly = provider.monthlyProduct;
    final yearly = provider.yearlyProduct;
    if (monthly == null || yearly == null) return 'BEST VALUE';
    final monthlyCost = monthly.rawPrice * 12;
    if (monthlyCost <= 0 ||
        yearly.rawPrice <= 0 ||
        yearly.rawPrice >= monthlyCost) {
      return 'BEST VALUE';
    }
    final savings = (1 - (yearly.rawPrice / monthlyCost)) * 100;
    return 'SAVE ${savings.round()}%';
  }
}

/// Gold medal that turns 360°, inside a slowly rotating dashed halo.
class _ProBadge extends StatefulWidget {
  const _ProBadge({required this.size});

  final double size;

  @override
  State<_ProBadge> createState() => _ProBadgeState();
}

class _ProBadgeState extends State<_ProBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _halo = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void dispose() {
    _halo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final medal = Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE08A), _gold, _goldDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.55),
            blurRadius: 36,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(Icons.block_rounded, color: Colors.white, size: s * 0.52),
    );

    return SizedBox(
      width: s * 1.55,
      height: s * 1.55,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotationTransition(
            turns: _halo,
            child: CustomPaint(
              size: Size.square(s * 1.5),
              painter: _HaloPainter(),
            ),
          ),
          Spin360(
            duration: const Duration(milliseconds: 5000),
            back: Container(
              width: s,
              height: s,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_goldDeep, Color(0xFFB45309)],
                ),
              ),
              child: Center(
                child: Text(
                  'NO ADS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: s * 0.17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            child: medal,
          ),
        ],
      ),
    );
  }
}

class _HaloPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 4;
    final dash = Paint()
      ..color = _gold.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const n = 40;
    for (var i = 0; i < n; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        i * 2 * math.pi / n,
        math.pi / n * 0.8,
        false,
        dash,
      );
    }
    // Sparkles
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2 + math.pi / 4;
      final p = c + Offset(math.cos(a), math.sin(a)) * r;
      canvas.drawCircle(p, 4, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        8,
        Paint()
          ..color = _gold.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
  }

  @override
  bool shouldRepaint(_HaloPainter oldDelegate) => false;
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.label,
    required this.periodSuffix,
    required this.perMonth,
    required this.selected,
    required this.isDark,
    required this.onTap,
    this.product,
    this.badge,
  });

  final String label;
  final String periodSuffix;
  final String perMonth;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  final ProductDetails? product;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final available = product != null;
    final muted = isDark ? Colors.white54 : Colors.black45;

    return GestureDetector(
      onTap: available ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: selected
              ? const LinearGradient(colors: [_gold, _goldDeep])
              : null,
          color: selected ? null : (isDark ? Colors.white12 : Colors.black12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark ? const Color(0xFF111A2E) : Colors.white,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? _goldDeep : Colors.transparent,
                  border: Border.all(
                    color: selected ? _goldDeep : muted,
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  ThemeConstants.signalRed,
                                  ThemeConstants.signalOrange,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      available ? perMonth : 'Not available on this device',
                      style: TextStyle(fontSize: 11.5, color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    available ? product!.price : '—',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: available ? null : muted,
                    ),
                  ),
                  Text(
                    periodSuffix,
                    style: TextStyle(fontSize: 11, color: muted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({
    required this.busy,
    required this.enabled,
    required this.label,
    required this.onTap,
  });

  final bool busy;
  final bool enabled;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled || busy ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(colors: [_gold, _goldDeep]),
            boxShadow: [
              BoxShadow(
                color: _goldDeep.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: busy
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.block_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
