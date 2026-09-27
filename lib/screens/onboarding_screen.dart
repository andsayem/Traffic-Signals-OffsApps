import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/translations.dart';
import '../utils/theme_constants.dart';
import '../widgets/traffic_sign_painter.dart';
import 'main_navigation_wrapper.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();

  // Drives the road scene (one seamless cycle, deliberately slow).
  late final AnimationController _road = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 32),
  )..repeat();
  int _currentPage = 0;

  // One traffic-light colour per step: red → yellow → green.
  static const _pages = [
    _OnboardingData(
      titleKey: 'onboarding_title_1',
      subtitleKey: 'onboarding_subtitle_1',
      signId: 'keep_left',
      accent: ThemeConstants.signalRed,
      icon: Icons.public_rounded,
    ),
    _OnboardingData(
      titleKey: 'onboarding_title_2',
      subtitleKey: 'onboarding_subtitle_2',
      signId: 'school_zone',
      accent: ThemeConstants.signalYellow,
      icon: Icons.menu_book_rounded,
    ),
    _OnboardingData(
      titleKey: 'onboarding_title_3',
      subtitleKey: 'onboarding_subtitle_3',
      signId: 'stop',
      accent: ThemeConstants.signalGreen,
      icon: Icons.emoji_events_rounded,
    ),
  ];

  bool get _isLast => _currentPage == _pages.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    _road.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      _completeOnboarding();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _pages[_currentPage].accent;
    final textPrimary = isDark ? Colors.white : ThemeConstants.lightTextPrimary;
    final textSecondary = isDark
        ? ThemeConstants.darkTextSecondary
        : ThemeConstants.lightTextSecondary;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.35),
            radius: 1.1,
            colors: [
              accent.withValues(alpha: isDark ? 0.28 : 0.22),
              isDark ? ThemeConstants.darkBgStart : ThemeConstants.lightBgStart,
              isDark ? ThemeConstants.darkBgEnd : ThemeConstants.lightBgEnd,
            ],
            stops: const [0, 0.55, 1],
          ),
        ),
        child: Stack(
          children: [
            // Bangladesh road scene behind everything
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _road,
                  builder: (context, _) => CustomPaint(
                    painter: _BdRoadPainter(
                      progress: _road.value,
                      accent: accent,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // Top bar: brand + skip
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                    child: Row(
                      children: [
                        const _TrafficLightDots(),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.tr('app_title'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 250),
                          opacity: _isLast ? 0 : 1,
                          child: TextButton(
                            onPressed: _isLast ? null : _completeOnboarding,
                            child: Text(
                              context.tr('skip'),
                              style: TextStyle(
                                color: textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Hero (swipeable)
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (index) =>
                          setState(() => _currentPage = index),
                      itemCount: _pages.length,
                      itemBuilder: (context, index) => Center(
                        child: _SignStage(
                          signId: _pages[index].signId,
                          accent: _pages[index].accent,
                        ),
                      ),
                    ),
                  ),

                  // Bottom glass panel
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : Colors.black.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStepLabel(accent),
                              const SizedBox(height: 14),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 350),
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.15),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    ),
                                child: Column(
                                  key: ValueKey(_currentPage),
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr(_pages[_currentPage].titleKey),
                                      style: TextStyle(
                                        fontSize: 26,
                                        height: 1.2,
                                        fontWeight: FontWeight.w900,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      context.tr(
                                        _pages[_currentPage].subtitleKey,
                                      ),
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        height: 1.55,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 22),
                              _buildProgressBars(isDark),
                              const SizedBox(height: 18),
                              _buildCtaButton(context, accent),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepLabel(Color accent) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_pages[_currentPage].icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            '${(_currentPage + 1).toString().padLeft(2, '0')} / '
            '${_pages.length.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBars(bool isDark) {
    return Row(
      children: List.generate(_pages.length, (index) {
        final active = index <= _currentPage;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            margin: EdgeInsets.only(right: index == _pages.length - 1 ? 0 : 6),
            height: 5,
            decoration: BoxDecoration(
              color: active
                  ? _pages[index].accent
                  : (isDark ? Colors.white12 : Colors.black12),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCtaButton(BuildContext context, Color accent) {
    // Yellow needs dark text to stay readable.
    final onAccent = accent == ThemeConstants.signalYellow
        ? ThemeConstants.lightTextPrimary
        : Colors.white;
    return GestureDetector(
      onTap: _next,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent, Color.lerp(accent, Colors.black, 0.18)!],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.tr(_isLast ? 'get_started' : 'next'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: onAccent,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              _isLast
                  ? Icons.rocket_launch_rounded
                  : Icons.arrow_forward_rounded,
              size: 20,
              color: onAccent,
            ),
          ],
        ),
      ),
    );
  }

  void _completeOnboarding() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    appProvider.completeOnboarding();
    // No ad here: first-run users go straight into the app.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigationWrapper()),
    );
  }
}

class _OnboardingData {
  final String titleKey;
  final String subtitleKey;
  final String signId;
  final Color accent;
  final IconData icon;

  const _OnboardingData({
    required this.titleKey,
    required this.subtitleKey,
    required this.signId,
    required this.accent,
    required this.icon,
  });
}

/// Small red/yellow/green traffic-light mark used as the brand badge.
class _TrafficLightDots extends StatelessWidget {
  const _TrafficLightDots();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (final c in const [
            ThemeConstants.signalRed,
            ThemeConstants.signalYellow,
            ThemeConstants.signalGreen,
          ])
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: c.withValues(alpha: 0.7), blurRadius: 4),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The hero: a road sign doing a 3D 360° turn (then resting), circled by a
/// rotating dashed ring with orbiting traffic-light dots, a soft accent
/// glow behind and a floor shadow below.
class _SignStage extends StatefulWidget {
  const _SignStage({required this.signId, required this.accent});

  final String signId;
  final Color accent;

  @override
  State<_SignStage> createState() => _SignStageState();
}

class _SignStageState extends State<_SignStage> with TickerProviderStateMixin {
  // Sign: one full 360° turn, then a rest, repeated.
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6500),
  )..repeat();

  // Orbit ring: slow continuous 360°.
  late final AnimationController _orbit = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  static const _spinCurve = Interval(0.0, 0.55, curve: Curves.easeInOutCubic);
  static const double _signSize = 170;
  static const double _stageSize = 290;

  @override
  void dispose() {
    _spin.dispose();
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sign = TrafficSignWidget(
      signId: widget.signId,
      size: _signSize,
      isGlowing: true,
    );
    // Back of the sign: same silhouette, brushed-metal grey.
    final back = ColorFiltered(
      colorFilter: const ColorFilter.mode(Color(0xFF94A3B8), BlendMode.srcIn),
      child: TrafficSignWidget(signId: widget.signId, size: _signSize),
    );

    return SizedBox(
      width: _stageSize,
      height: _stageSize + 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Accent glow
          Positioned(
            top: 20,
            child: Container(
              width: _stageSize - 40,
              height: _stageSize - 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.accent.withValues(alpha: 0.35),
                    widget.accent.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),

          // Rotating 360° orbit ring with traffic-light dots
          Positioned(
            top: 0,
            child: AnimatedBuilder(
              animation: _orbit,
              builder: (context, _) => Transform.rotate(
                angle: _orbit.value * 2 * math.pi,
                child: CustomPaint(
                  size: const Size.square(_stageSize),
                  painter: _OrbitPainter(accent: widget.accent),
                ),
              ),
            ),
          ),

          // Floor shadow that narrows as the sign turns edge-on
          Positioned(
            bottom: 8,
            child: AnimatedBuilder(
              animation: _spin,
              builder: (context, _) {
                final angle = _spinCurve.transform(_spin.value) * 2 * math.pi;
                final width = 60 + 70 * math.cos(angle).abs();
                return Container(
                  width: width,
                  height: 14,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: RadialGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // The spinning sign
          Positioned(
            top: (_stageSize - _signSize) / 2,
            child: AnimatedBuilder(
              animation: _spin,
              builder: (context, _) {
                final angle = _spinCurve.transform(_spin.value) * 2 * math.pi;
                final showBack = math.cos(angle) < 0;
                // Gentle float while resting.
                final bob = math.sin(_spin.value * 2 * math.pi) * 6;
                return Transform.translate(
                  offset: Offset(0, bob),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0012) // perspective
                      ..rotateY(angle),
                    child: showBack
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationY(math.pi),
                            child: back,
                          )
                        : sign,
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

class _OrbitPainter extends CustomPainter {
  _OrbitPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 8;

    // Dashed ring
    final dash = Paint()
      ..color = accent.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const segments = 48;
    const sweep = 2 * math.pi / segments;
    for (var i = 0; i < segments; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweep,
        sweep * 0.45,
        false,
        dash,
      );
    }

    // Inner thin ring
    canvas.drawCircle(
      center,
      radius - 16,
      Paint()
        ..color = accent.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Orbiting traffic-light dots, 120° apart
    const colors = [
      ThemeConstants.signalRed,
      ThemeConstants.signalYellow,
      ThemeConstants.signalGreen,
    ];
    for (var i = 0; i < colors.length; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 3;
      final p = center + Offset(math.cos(a), math.sin(a)) * radius;
      canvas.drawCircle(
        p,
        11,
        Paint()
          ..color = colors[i].withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(p, 7, Paint()..color = colors[i]);
      canvas.drawCircle(
        p,
        2.5,
        Paint()..color = Colors.white.withValues(alpha: 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) => oldDelegate.accent != accent;
}

/// A Bangladesh-style road in perspective: green fields either side, grey
/// asphalt with yellow edge lines and a dashed white centre line, and
/// roadside posts (traffic light + zebra crossing, speed limit, warning,
/// keep-left) that slowly roll toward the viewer. Traffic keeps left.
class _BdRoadPainter extends CustomPainter {
  _BdRoadPainter({
    required this.progress,
    required this.accent,
    required this.isDark,
  });

  /// 0..1 over one full cycle; every post advances exactly one slot.
  final double progress;
  final Color accent;
  final bool isDark;

  static const int _posts = 4;
  static const int _dashes = 8; // multiple of _posts keeps the loop seamless

  late double _w, _h, _horizon, _cx, _topHalf, _bottomHalf;

  // Screen y / road half-width at depth d (0 = horizon, 1 = bottom edge).
  // Squaring d gives real-road foreshortening.
  double _yAt(double d) => _horizon + (_h - _horizon) * d * d;
  double _halfAt(double d) => _topHalf + (_bottomHalf - _topHalf) * d * d;

  @override
  void paint(Canvas canvas, Size size) {
    _w = size.width;
    _h = size.height;
    _horizon = _h * 0.52;
    _cx = _w / 2;
    _topHalf = _w * 0.07;
    _bottomHalf = _w * 0.92;

    _paintFields(canvas);
    _paintRoad(canvas);
    _paintCentreLine(canvas);

    // Posts, far to near so nearer ones draw on top.
    final posts = <(int, double)>[
      for (var i = 0; i < _posts; i++)
        (i, ((i + progress * _posts) % _posts) / _posts),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    for (final (type, depth) in posts) {
      if (type == 0) _paintZebra(canvas, depth);
      _paintPost(canvas, type, depth);
    }
  }

  void _paintFields(Canvas canvas) {
    final rect = Rect.fromLTWH(0, _horizon - 1, _w, _h - _horizon + 1);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0x000E6B45), Color(0xFF0E6B45), Color(0xFF063F29)]
              : const [Color(0x0034A56F), Color(0xFF34A56F), Color(0xFF1E7D4F)],
          stops: const [0, 0.25, 1],
        ).createShader(rect),
    );

    // Accent glow sitting on the horizon
    final glow = Rect.fromCircle(
      center: Offset(_cx, _horizon),
      radius: _w * 0.4,
    );
    canvas.drawOval(
      glow,
      Paint()
        ..shader = RadialGradient(
          colors: [accent.withValues(alpha: 0.28), accent.withValues(alpha: 0)],
        ).createShader(glow),
    );
  }

  void _paintRoad(Canvas canvas) {
    final rect = Rect.fromLTWH(0, _horizon, _w, _h - _horizon);
    final road = Path()
      ..moveTo(_cx - _topHalf, _horizon)
      ..lineTo(_cx + _topHalf, _horizon)
      ..lineTo(_cx + _bottomHalf, _h)
      ..lineTo(_cx - _bottomHalf, _h)
      ..close();
    canvas.drawPath(
      road,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0x00575E69), Color(0xFF4A515C), Color(0xFF2F343C)]
              : const [Color(0x00707885), Color(0xFF6B7380), Color(0xFF4B525D)],
          stops: const [0, 0.12, 1],
        ).createShader(rect),
    );

    // Yellow edge lines
    final edge = Paint()
      ..color = ThemeConstants.signalYellow
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    const inset = 0.94;
    for (final side in const [-1.0, 1.0]) {
      canvas.drawLine(
        Offset(_cx + side * _topHalf * inset, _horizon),
        Offset(_cx + side * _bottomHalf * inset, _h),
        edge,
      );
    }
  }

  void _paintCentreLine(Canvas canvas) {
    final phase = (progress * _dashes) % 1;
    final paint = Paint();
    for (var i = 0; i < _dashes; i++) {
      final d0 = (i + phase) / _dashes;
      final d1 = math.min(1.0, d0 + 0.5 / _dashes);
      final t0 = 1.5 + 6 * d0 * d0; // thicker up close
      final t1 = 1.5 + 6 * d1 * d1;
      paint.color = Colors.white.withValues(alpha: 0.35 + 0.6 * d0);
      canvas.drawPath(
        Path()
          ..moveTo(_cx - t0 / 2, _yAt(d0))
          ..lineTo(_cx + t0 / 2, _yAt(d0))
          ..lineTo(_cx + t1 / 2, _yAt(d1))
          ..lineTo(_cx - t1 / 2, _yAt(d1))
          ..close(),
        paint,
      );
    }
  }

  void _paintZebra(Canvas canvas, double depth) {
    if (depth < 0.12) return;
    final far = depth, near = math.min(1.0, depth + 0.06);
    final y0 = _yAt(far), y1 = _yAt(near);
    final half0 = _halfAt(far) * 0.9, half1 = _halfAt(near) * 0.9;
    const stripes = 8;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8 * _fade(depth));
    for (var i = 0; i < stripes; i++) {
      final a = (i + 0.2) / stripes, b = (i + 0.75) / stripes;
      canvas.drawPath(
        Path()
          ..moveTo(_cx - half0 + 2 * half0 * a, y0)
          ..lineTo(_cx - half0 + 2 * half0 * b, y0)
          ..lineTo(_cx - half1 + 2 * half1 * b, y1)
          ..lineTo(_cx - half1 + 2 * half1 * a, y1)
          ..close(),
        paint,
      );
    }
  }

  // Posts appear gently at the horizon instead of popping in.
  double _fade(double depth) => (depth / 0.15).clamp(0.0, 1.0);

  void _paintPost(Canvas canvas, int type, double depth) {
    final alpha = _fade(depth);
    if (alpha <= 0) return;
    final scale = 0.08 + 0.92 * depth * depth;

    // Traffic light and warning on the left (keep-left side), others right.
    final side = (type == 0 || type == 2) ? -1.0 : 1.0;
    final baseX = _cx + side * _halfAt(depth) * 1.12;
    final baseY = _yAt(depth);
    final top = Offset(baseX, baseY - 150 * scale);

    canvas.drawLine(
      Offset(baseX, baseY),
      top,
      Paint()
        ..color = const Color(0xFFB0B8C4).withValues(alpha: alpha)
        ..strokeWidth = math.max(1.2, 5 * scale)
        ..strokeCap = StrokeCap.round,
    );

    final r = 30 * scale; // sign radius
    final c = top.translate(0, -r * 0.6);
    switch (type) {
      case 0:
        _trafficLight(canvas, c.translate(0, -r * 0.6), r, alpha);
      case 1:
        _speedLimit(canvas, c, r, alpha);
      case 2:
        _warning(canvas, c, r, alpha);
      default:
        _keepLeft(canvas, c, r, alpha);
    }
  }

  void _trafficLight(Canvas canvas, Offset c, double r, double alpha) {
    final box = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: r * 0.95, height: r * 2.5),
      Radius.circular(r * 0.25),
    );
    canvas.drawRRect(
      box,
      Paint()..color = const Color(0xFF111827).withValues(alpha: alpha),
    );
    // Cycles red, yellow, green as the post approaches.
    final lit = ((progress * _posts * 3) % 3).floor();
    const colors = [
      ThemeConstants.signalRed,
      ThemeConstants.signalYellow,
      ThemeConstants.signalGreen,
    ];
    for (var i = 0; i < 3; i++) {
      final p = c.translate(0, (i - 1) * r * 0.78);
      final on = i == lit;
      if (on) {
        canvas.drawCircle(
          p,
          r * 0.55,
          Paint()
            ..color = colors[i].withValues(alpha: 0.55 * alpha)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.3 + 0.1),
        );
      }
      canvas.drawCircle(
        p,
        r * 0.3,
        Paint()..color = colors[i].withValues(alpha: (on ? 1.0 : 0.22) * alpha),
      );
    }
  }

  void _speedLimit(Canvas canvas, Offset c, double r, double alpha) {
    canvas.drawCircle(
      c,
      r,
      Paint()..color = Colors.white.withValues(alpha: alpha),
    );
    canvas.drawCircle(
      c,
      r * 0.86,
      Paint()
        ..color = ThemeConstants.signalRed.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.22,
    );
    _text(canvas, '40', c, r * 0.8, Colors.black.withValues(alpha: alpha));
  }

  void _warning(Canvas canvas, Offset c, double r, double alpha) {
    final tri = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r * 1.05, c.dy + r * 0.8)
      ..lineTo(c.dx - r * 1.05, c.dy + r * 0.8)
      ..close();
    canvas.drawPath(
      tri,
      Paint()..color = Colors.white.withValues(alpha: alpha),
    );
    canvas.drawPath(
      tri,
      Paint()
        ..color = ThemeConstants.signalRed.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.2
        ..strokeJoin = StrokeJoin.round,
    );
    _text(
      canvas,
      '!',
      c.translate(0, r * 0.15),
      r * 0.95,
      Colors.black.withValues(alpha: alpha),
    );
  }

  void _keepLeft(Canvas canvas, Offset c, double r, double alpha) {
    canvas.drawCircle(
      c,
      r,
      Paint()..color = ThemeConstants.signalBlue.withValues(alpha: alpha),
    );
    canvas.drawCircle(
      c,
      r * 0.93,
      Paint()
        ..color = Colors.white.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.1,
    );
    // Arrow pointing down-left
    final arrow = Paint()
      ..color = Colors.white.withValues(alpha: alpha)
      ..strokeWidth = r * 0.22
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final tip = c.translate(-r * 0.4, r * 0.4);
    canvas.drawLine(c.translate(r * 0.4, -r * 0.4), tip, arrow);
    canvas.drawLine(tip, tip.translate(r * 0.45, 0), arrow);
    canvas.drawLine(tip, tip.translate(0, -r * 0.45), arrow);
  }

  void _text(Canvas canvas, String s, Offset c, double fontSize, Color color) {
    if (fontSize < 3) return;
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_BdRoadPainter old) =>
      old.progress != progress || old.accent != accent || old.isDark != isDark;
}
