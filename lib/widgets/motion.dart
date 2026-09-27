import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../utils/theme_constants.dart';
import 'traffic_sign_painter.dart';

/// Turns [child] a full 360° around its vertical axis (like a road sign
/// spinning on its pole), rests, and repeats. While the back faces the
/// viewer, [back] is shown instead (defaults to a mirrored [child]).
///
/// [delay] staggers several spinners so a grid doesn't turn in lockstep.
class Spin360 extends StatefulWidget {
  const Spin360({
    super.key,
    required this.child,
    this.back,
    this.duration = const Duration(milliseconds: 6000),
    this.delay = Duration.zero,
    this.spinFraction = 0.4,
  });

  final Widget child;
  final Widget? back;
  final Duration duration;
  final Duration delay;

  /// Part of [duration] spent turning; the rest is a pause.
  final double spinFraction;

  @override
  State<Spin360> createState() => _Spin360State();
}

class _Spin360State extends State<Spin360> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) _c.repeat();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = Interval(
      0,
      widget.spinFraction,
      curve: Curves.easeInOutCubic,
    );
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final angle = curve.transform(_c.value) * 2 * math.pi;
        final showBack = math.cos(angle) < 0;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(angle),
          child: showBack
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(math.pi),
                  child: widget.back ?? widget.child,
                )
              : widget.child,
        );
      },
    );
  }
}

/// A traffic sign that spins 360° with a brushed-metal back face.
class SpinningSign extends StatelessWidget {
  const SpinningSign({
    super.key,
    required this.signId,
    this.size = 60,
    this.isGlowing = false,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 6000),
  });

  final String signId;
  final double size;
  final bool isGlowing;
  final Duration delay;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Spin360(
      delay: delay,
      duration: duration,
      back: ColorFiltered(
        colorFilter: const ColorFilter.mode(Color(0xFF94A3B8), BlendMode.srcIn),
        child: TrafficSignWidget(signId: signId, size: size),
      ),
      child: TrafficSignWidget(
        signId: signId,
        size: size,
        isGlowing: isGlowing,
      ),
    );
  }
}

/// Fades and slides [child] up into place once, [index] × [step] after it
/// first builds — used to stagger lists and grids.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.step = const Duration(milliseconds: 70),
    this.offset = 24,
  });

  final Widget child;
  final int index;
  final Duration step;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    // Cap the stagger so long lists don't wait forever.
    final wait = widget.step * math.min(widget.index, 10);
    Future<void>.delayed(wait, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _t.value) * widget.offset),
          child: child,
        ),
      ),
    );
  }
}

/// Icon that keeps turning 360° in the screen plane (e.g. a globe or
/// refresh mark), at a calm pace.
class RotatingIcon extends StatefulWidget {
  const RotatingIcon(
    this.icon, {
    super.key,
    this.color,
    this.size = 22,
    this.duration = const Duration(seconds: 8),
  });

  final IconData icon;
  final Color? color;
  final double size;
  final Duration duration;

  @override
  State<RotatingIcon> createState() => _RotatingIconState();
}

class _RotatingIconState extends State<RotatingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _c,
      child: Icon(widget.icon, color: widget.color, size: widget.size),
    );
  }
}

/// Section title with a tinted icon badge and optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.color = ThemeConstants.signalRed,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 24, 16, 12),
  });

  final String title;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? Colors.white
                        : ThemeConstants.lightTextPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? ThemeConstants.darkTextSecondary
                          : ThemeConstants.lightTextSecondary,
                    ),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
